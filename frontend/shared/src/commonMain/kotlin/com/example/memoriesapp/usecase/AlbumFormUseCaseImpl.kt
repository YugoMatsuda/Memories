package com.example.memoriesapp.usecase

import com.example.memoriesapp.core.LocalId
import com.example.memoriesapp.core.SyncStatus
import com.example.memoriesapp.core.Timestamp
import com.example.memoriesapp.domain.Album
import com.example.memoriesapp.domain.EntityType
import com.example.memoriesapp.domain.MimeType
import com.example.memoriesapp.domain.OperationType
import com.example.memoriesapp.gateway.AlbumGateway
import com.example.memoriesapp.mapper.AlbumMapper
import com.example.memoriesapp.repository.AlbumRepository
import com.example.memoriesapp.domain.ImageEntityType
import com.example.memoriesapp.repository.ImageStorageRepository
import com.example.memoriesapp.repository.ReachabilityRepository

/**
 * Result of album create operation
 */
sealed class AlbumCreateResult {
    data class Success(val album: Album) : AlbumCreateResult()
    data class SuccessPendingSync(val album: Album) : AlbumCreateResult()
    data class Failure(val error: AlbumCreateError) : AlbumCreateResult()
}

enum class AlbumCreateError {
    NETWORK_ERROR,
    SERVER_ERROR,
    IMAGE_STORAGE_FAILED,
    DATABASE_ERROR,
    UNKNOWN
}

/**
 * Result of album update operation
 */
sealed class AlbumUpdateResult {
    data class Success(val album: Album) : AlbumUpdateResult()
    data class SuccessPendingSync(val album: Album) : AlbumUpdateResult()
    data class Failure(val error: AlbumUpdateError) : AlbumUpdateResult()
}

enum class AlbumUpdateError {
    NETWORK_ERROR,
    SERVER_ERROR,
    NOT_FOUND,
    IMAGE_STORAGE_FAILED,
    DATABASE_ERROR,
    UNKNOWN
}

/**
 * UseCase for album create/edit form
 */
class AlbumFormUseCaseImpl(
    private val albumRepository: AlbumRepository,
    private val albumGateway: AlbumGateway,
    private val syncQueueService: SyncQueueService,
    private val reachabilityRepository: ReachabilityRepository,
    private val imageStorageRepository: ImageStorageRepository
) : AlbumFormUseCase {
    override suspend fun createAlbum(title: String, coverImageData: ByteArray?): AlbumCreateResult {
        val localId = LocalId.generate()

        // 1. Save cover image locally
        var localImagePath: String? = null
        if (coverImageData != null) {
            try {
                localImagePath = imageStorageRepository.save(coverImageData, ImageEntityType.ALBUM_COVER, localId)
            } catch (e: Exception) {
                return AlbumCreateResult.Failure(AlbumCreateError.IMAGE_STORAGE_FAILED)
            }
        }

        // 2. Save to local DB (Optimistic)
        val album = Album(
            serverId = null,
            localId = localId,
            title = title,
            coverImageUrl = null,
            coverImageLocalPath = localImagePath,
            createdAt = Timestamp.now(),
            syncStatus = SyncStatus.PENDING_CREATE
        )
        try {
            albumRepository.insert(album)
        } catch (e: Exception) {
            return AlbumCreateResult.Failure(AlbumCreateError.DATABASE_ERROR)
        }

        // 3. If offline, enqueue and return
        if (!reachabilityRepository.isConnected) {
            syncQueueService.enqueue(EntityType.ALBUM, OperationType.CREATE, localId)
            return AlbumCreateResult.SuccessPendingSync(album)
        }

        // 4. If online, sync immediately
        return syncCreate(album, coverImageData)
    }

    override suspend fun updateAlbum(album: Album, title: String, coverImageData: ByteArray?): AlbumUpdateResult {
        val localId = album.localId

        // 1. Save cover image locally if provided
        var localImagePath: String? = album.coverImageLocalPath
        if (coverImageData != null) {
            try {
                localImagePath = imageStorageRepository.save(coverImageData, ImageEntityType.ALBUM_COVER, localId)
            } catch (e: Exception) {
                return AlbumUpdateResult.Failure(AlbumUpdateError.IMAGE_STORAGE_FAILED)
            }
        }

        // 2. Update local DB (Optimistic)
        val updatedAlbum = Album(
            serverId = album.serverId,
            localId = localId,
            title = title,
            coverImageUrl = album.coverImageUrl,
            coverImageLocalPath = localImagePath,
            createdAt = album.createdAt,
            syncStatus = SyncStatus.PENDING_UPDATE
        )
        try {
            albumRepository.update(updatedAlbum)
        } catch (e: Exception) {
            return AlbumUpdateResult.Failure(AlbumUpdateError.DATABASE_ERROR)
        }

        // 3. If offline or not synced yet, enqueue and return
        if (!reachabilityRepository.isConnected) {
            syncQueueService.enqueue(EntityType.ALBUM, OperationType.UPDATE, localId)
            return AlbumUpdateResult.SuccessPendingSync(updatedAlbum)
        }

        val serverId = album.serverId
        if (serverId == null) {
            // Not synced yet, enqueue for later
            syncQueueService.enqueue(EntityType.ALBUM, OperationType.UPDATE, localId)
            return AlbumUpdateResult.SuccessPendingSync(updatedAlbum)
        }

        // 4. If online, sync immediately
        return syncUpdate(updatedAlbum, serverId, coverImageData)
    }

    private suspend fun syncCreate(album: Album, coverImageData: ByteArray?): AlbumCreateResult {
        return try {
            // API call
            var response = albumGateway.createAlbum(title = album.title, coverImageUrl = null)

            // Upload cover image
            if (coverImageData != null) {
                response = albumGateway.uploadCoverImage(
                    albumId = response.id,
                    fileData = coverImageData,
                    fileName = MimeType.JPEG.fileName(album.localId),
                    mimeType = MimeType.JPEG.value
                )
                // Delete local image
                imageStorageRepository.delete(ImageEntityType.ALBUM_COVER, album.localId)
            }

            // Update local DB
            albumRepository.markAsSynced(album.localId, response.id)

            val syncedAlbum = AlbumMapper.toDomain(response, album.localId)
            AlbumCreateResult.Success(syncedAlbum)
        } catch (e: Exception) {
            // Sync failed, enqueue for later
            try {
                albumRepository.update(album.copy(syncStatus = SyncStatus.FAILED))
            } catch (updateError: Exception) {
                println("[AlbumFormUseCase] Failed to update album status to failed: $updateError")
            }
            syncQueueService.enqueue(EntityType.ALBUM, OperationType.CREATE, album.localId)
            AlbumCreateResult.SuccessPendingSync(album)
        }
    }

    private suspend fun syncUpdate(album: Album, serverId: Int, coverImageData: ByteArray?): AlbumUpdateResult {
        return try {
            // API call
            var response = albumGateway.updateAlbum(albumId = serverId, title = album.title, coverImageUrl = null)

            // Upload cover image
            if (coverImageData != null) {
                response = albumGateway.uploadCoverImage(
                    albumId = serverId,
                    fileData = coverImageData,
                    fileName = MimeType.JPEG.fileName(album.localId),
                    mimeType = MimeType.JPEG.value
                )
                // Delete local image
                imageStorageRepository.delete(ImageEntityType.ALBUM_COVER, album.localId)
            }

            val syncedAlbum = AlbumMapper.toDomain(response, album.localId)
            albumRepository.update(syncedAlbum)
            AlbumUpdateResult.Success(syncedAlbum)
        } catch (e: Exception) {
            // Sync failed, enqueue for later
            try {
                albumRepository.update(album.copy(syncStatus = SyncStatus.FAILED))
            } catch (updateError: Exception) {
                println("[AlbumFormUseCase] Failed to update album status to failed: $updateError")
            }
            syncQueueService.enqueue(EntityType.ALBUM, OperationType.UPDATE, album.localId)
            AlbumUpdateResult.SuccessPendingSync(album)
        }
    }
}
