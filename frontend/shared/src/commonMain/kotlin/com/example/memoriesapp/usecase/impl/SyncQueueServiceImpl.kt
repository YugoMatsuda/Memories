package com.example.memoriesapp.usecase.impl

import com.example.memoriesapp.core.LocalId
import com.example.memoriesapp.core.SyncStatus
import com.example.memoriesapp.core.Timestamp
import com.example.memoriesapp.domain.EntityType
import com.example.memoriesapp.domain.ImageEntityType
import com.example.memoriesapp.domain.MimeType
import com.example.memoriesapp.domain.OperationType
import com.example.memoriesapp.domain.SyncOperation
import com.example.memoriesapp.domain.SyncOperationStatus
import com.example.memoriesapp.gateway.AlbumGateway
import com.example.memoriesapp.gateway.MemoryGateway
import com.example.memoriesapp.gateway.UserGateway
import com.example.memoriesapp.mapper.UserMapper
import com.example.memoriesapp.repository.AlbumRepository
import com.example.memoriesapp.repository.ImageStorageRepository
import com.example.memoriesapp.repository.MemoryRepository
import com.example.memoriesapp.repository.ReachabilityRepository
import com.example.memoriesapp.repository.SyncQueueRepository
import com.example.memoriesapp.repository.UserRepository
import com.example.memoriesapp.usecase.SyncError
import com.example.memoriesapp.usecase.SyncQueueService
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/**
 * Service for processing sync queue operations
 */
class SyncQueueServiceImpl(
    private val syncQueueRepository: SyncQueueRepository,
    private val albumRepository: AlbumRepository,
    private val memoryRepository: MemoryRepository,
    private val userRepository: UserRepository,
    private val albumGateway: AlbumGateway,
    private val memoryGateway: MemoryGateway,
    private val userGateway: UserGateway,
    private val imageStorageRepository: ImageStorageRepository,
    private val reachabilityRepository: ReachabilityRepository
) : SyncQueueService {
    private val scope = CoroutineScope(Dispatchers.Default)

    /**
     * Enqueue a sync operation
     */
    override fun enqueue(entityType: EntityType, operationType: OperationType, localId: LocalId) {
        val operation = SyncOperation(
            id = LocalId.generate(),
            entityType = entityType,
            operationType = operationType,
            localId = localId,
            createdAt = Timestamp.now(),
            status = SyncOperationStatus.PENDING,
            errorMessage = null
        )
        scope.launch {
            try {
                syncQueueRepository.enqueue(operation)
            } catch (e: Exception) {
                println("[SyncQueueService] Failed to enqueue sync operation: $e")
            }
        }
    }

    /**
     * Process all pending operations in the queue
     */
    override suspend fun processQueue() {
        println("[SyncQueueService] processQueue")
        if (!reachabilityRepository.isConnected) return
        if (!syncQueueRepository.tryStartSyncing()) {
            println("[SyncQueueService] Already processing, skipping")
            return
        }
        try {
            val operations = syncQueueRepository.peek()
            if (operations.isEmpty()) {
                println("[SyncQueueService] there are no pending task")
                return
            }

            for (operation in operations) {
                try {
                    syncQueueRepository.updateStatus(operation.id, SyncOperationStatus.IN_PROGRESS, null)
                } catch (e: Exception) {
                    println("[SyncQueueService] Failed to update sync status to inProgress: $e")
                }

                try {
                    execute(operation)
                    try {
                        syncQueueRepository.remove(operation.id)
                    } catch (e: Exception) {
                        println("[SyncQueueService] Failed to remove completed sync operation: $e")
                    }
                } catch (syncError: Exception) {
                    val errorMessage = mapErrorMessage(syncError)
                    println("[SyncQueueService] Sync failed: $errorMessage")
                    try {
                        syncQueueRepository.updateStatus(operation.id, SyncOperationStatus.FAILED, errorMessage)
                    } catch (e: Exception) {
                        println("[SyncQueueService] Failed to update sync status to failed: $e")
                    }
                }
            }
        } finally {
            syncQueueRepository.stopSyncing()
        }
    }

    private suspend fun execute(operation: SyncOperation) {
        when (operation.entityType) {
            EntityType.ALBUM -> executeAlbum(operation)
            EntityType.MEMORY -> executeMemory(operation)
            EntityType.USER -> executeUser(operation)
        }
    }

    private suspend fun executeAlbum(operation: SyncOperation) {
        when (operation.operationType) {
            OperationType.CREATE -> executeAlbumCreate(operation)
            OperationType.UPDATE -> executeAlbumUpdate(operation)
        }
    }

    private suspend fun executeMemory(operation: SyncOperation) {
        when (operation.operationType) {
            OperationType.CREATE -> executeMemoryCreate(operation)
            OperationType.UPDATE -> println("[SyncQueueService] Memory update is not supported")
        }
    }

    private suspend fun executeUser(operation: SyncOperation) {
        when (operation.operationType) {
            OperationType.CREATE -> println("[SyncQueueService] User create is not supported")
            OperationType.UPDATE -> executeUserUpdate(operation)
        }
    }

    private suspend fun executeAlbumCreate(operation: SyncOperation) {
        var album = albumRepository.getByLocalId(operation.localId)
            ?: run {
                println("[SyncQueueService] Album not found for localId: ${operation.localId}")
                return
            }

        println("[SyncQueueService] executeAlbumCreate - localId: ${album.localId}, serverId: ${album.serverId}")

        // 1. Create album on server if not yet synced
        if (album.serverId == null) {
            val response = albumGateway.createAlbum(title = album.title, coverImageUrl = null)
            val serverId = response.id
            println("[SyncQueueService] Album created on server with id: $serverId")
            albumRepository.markAsSynced(operation.localId, serverId)
            println("[SyncQueueService] Album marked as synced")
            album = album.copy(serverId = serverId, syncStatus = SyncStatus.SYNCED)
        }

        // 2. Upload cover image if exists locally
        val serverId = album.serverId
        if (album.coverImageLocalPath != null && serverId != null) {
            try {
                val imageData = imageStorageRepository.get(ImageEntityType.ALBUM_COVER, operation.localId)
                val response = albumGateway.uploadCoverImage(
                    albumId = serverId,
                    fileData = imageData,
                    fileName = MimeType.JPEG.fileName(operation.localId),
                    mimeType = MimeType.JPEG.value
                )
                response.coverImageUrl?.let { coverUrl ->
                    albumRepository.updateCoverImageUrl(operation.localId, coverUrl)
                }
                imageStorageRepository.delete(ImageEntityType.ALBUM_COVER, operation.localId)
            } catch (e: Exception) {
                println("[SyncQueueService] Failed to upload cover image: $e")
            }
        }
    }

    private suspend fun executeAlbumUpdate(operation: SyncOperation) {
        val album = albumRepository.getByLocalId(operation.localId) ?: return
        val serverId = album.serverId ?: return

        // 1. Update album on server
        albumGateway.updateAlbum(albumId = serverId, title = album.title, coverImageUrl = null)

        // 2. Upload cover image if exists locally
        if (album.coverImageLocalPath != null) {
            try {
                val imageData = imageStorageRepository.get(ImageEntityType.ALBUM_COVER, operation.localId)
                val response = albumGateway.uploadCoverImage(
                    albumId = serverId,
                    fileData = imageData,
                    fileName = MimeType.JPEG.fileName(operation.localId),
                    mimeType = MimeType.JPEG.value
                )
                response.coverImageUrl?.let { coverUrl ->
                    albumRepository.updateCoverImageUrl(operation.localId, coverUrl)
                }
                imageStorageRepository.delete(ImageEntityType.ALBUM_COVER, operation.localId)
            } catch (e: Exception) {
                println("[SyncQueueService] Failed to upload cover image: $e")
            }
        }

        // 3. Mark as synced
        val updatedAlbum = album.copy(syncStatus = SyncStatus.SYNCED)
        albumRepository.update(updatedAlbum)
    }

    private suspend fun executeMemoryCreate(operation: SyncOperation) {
        val memory = memoryRepository.getByLocalId(operation.localId)
            ?: run {
                println("[SyncQueueService] Memory not found: ${operation.localId}")
                throw SyncError.EntityNotFound
            }

        println("[SyncQueueService] Memory albumId: ${memory.albumId}, albumLocalId: ${memory.albumLocalId}")

        // Get album server ID
        val albumServerId: Int = memory.albumId
            ?: run {
                // Album was created offline, look up by localId
                val album = albumRepository.getByLocalId(memory.albumLocalId)
                println("[SyncQueueService] Album lookup result: $album, serverId: ${album?.serverId}")
                album?.serverId ?: throw SyncError.DependencyNotSynced
            }

        // Get local image data
        val imageData = imageStorageRepository.get(ImageEntityType.MEMORY, operation.localId)

        // Upload to server
        val response = memoryGateway.uploadMemory(
            albumId = albumServerId,
            title = memory.title,
            imageRemoteUrl = null,
            fileData = imageData,
            fileName = MimeType.JPEG.fileName(operation.localId),
            mimeType = MimeType.JPEG.value
        )

        // Delete local image
        imageStorageRepository.delete(ImageEntityType.MEMORY, operation.localId)

        // Update local DB
        memoryRepository.markAsSynced(operation.localId, response.id)
    }

    private suspend fun executeUserUpdate(operation: SyncOperation) {
        val user = userRepository.get() ?: return

        // 1. Update profile on server
        var response = userGateway.updateUser(
            name = user.name,
            birthday = user.birthday?.toString(),
            avatarUrl = null
        )

        // 2. Upload avatar if exists locally
        if (user.avatarLocalPath != null) {
            try {
                val imageData = imageStorageRepository.get(ImageEntityType.AVATAR, operation.localId)
                response = userGateway.uploadAvatar(
                    fileData = imageData,
                    fileName = MimeType.JPEG.fileName(operation.localId),
                    mimeType = MimeType.JPEG.value
                )
                imageStorageRepository.delete(ImageEntityType.AVATAR, operation.localId)
            } catch (e: Exception) {
                println("[SyncQueueService] Failed to upload avatar: $e")
            }
        }

        // 3. Update local DB
        val syncedUser = UserMapper.toDomain(response)
        userRepository.set(syncedUser)
    }

    private fun mapErrorMessage(error: Exception): String {
        return when (error) {
            is SyncError.DependencyNotSynced -> "Album not synced yet"
            is SyncError.EntityNotFound -> "Entity not found in local DB"
            is SyncError.ImageNotFound -> "Image file not found"
            else -> error.message ?: "Unknown error"
        }
    }
}
