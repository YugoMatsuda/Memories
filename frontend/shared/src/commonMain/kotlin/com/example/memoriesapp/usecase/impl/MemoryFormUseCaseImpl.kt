package com.example.memoriesapp.usecase.impl

import com.example.memoriesapp.core.LocalId
import com.example.memoriesapp.core.SyncStatus
import com.example.memoriesapp.core.Timestamp
import com.example.memoriesapp.domain.Album
import com.example.memoriesapp.domain.EntityType
import com.example.memoriesapp.domain.ImageEntityType
import com.example.memoriesapp.domain.Memory
import com.example.memoriesapp.domain.MimeType
import com.example.memoriesapp.domain.OperationType
import com.example.memoriesapp.gateway.MemoryGateway
import com.example.memoriesapp.mapper.MemoryMapper
import com.example.memoriesapp.repository.ImageStorageRepository
import com.example.memoriesapp.repository.MemoryRepository
import com.example.memoriesapp.repository.ReachabilityRepository
import com.example.memoriesapp.usecase.MemoryCreateError
import com.example.memoriesapp.usecase.MemoryCreateResult
import com.example.memoriesapp.usecase.MemoryFormUseCase
import com.example.memoriesapp.usecase.SyncQueueService

/**
 * UseCase for memory create form
 */
class MemoryFormUseCaseImpl(
    private val memoryRepository: MemoryRepository,
    private val memoryGateway: MemoryGateway,
    private val syncQueueService: SyncQueueService,
    private val reachabilityRepository: ReachabilityRepository,
    private val imageStorageRepository: ImageStorageRepository
) : MemoryFormUseCase {
    override suspend fun createMemory(album: Album, title: String, imageData: ByteArray): MemoryCreateResult {
        val localId = LocalId.generate()

        // 1. Save image locally
        val localImagePath: String
        try {
            localImagePath = imageStorageRepository.save(imageData, ImageEntityType.MEMORY, localId)
        } catch (e: Exception) {
            return MemoryCreateResult.Failure(MemoryCreateError.IMAGE_STORAGE_FAILED)
        }

        // 2. Save to local DB (Optimistic)
        val memory = Memory(
            serverId = null,
            localId = localId,
            albumId = album.serverId,
            albumLocalId = album.localId,
            title = title,
            imageUrl = null,
            imageLocalPath = localImagePath,
            createdAt = Timestamp.now(),
            syncStatus = SyncStatus.PENDING_CREATE
        )
        try {
            memoryRepository.insert(memory)
        } catch (e: Exception) {
            return MemoryCreateResult.Failure(MemoryCreateError.DATABASE_ERROR)
        }

        // 3. If offline or album not synced, enqueue and return
        if (!reachabilityRepository.isConnected) {
            syncQueueService.enqueue(EntityType.MEMORY, OperationType.CREATE, localId)
            return MemoryCreateResult.SuccessPendingSync(memory)
        }

        val albumServerId = album.serverId
        if (albumServerId == null) {
            // Album not synced yet, enqueue for later
            syncQueueService.enqueue(EntityType.MEMORY, OperationType.CREATE, localId)
            return MemoryCreateResult.SuccessPendingSync(memory)
        }

        // 4. If online and album synced, sync immediately
        return syncCreate(memory, albumServerId, imageData)
    }

    private suspend fun syncCreate(memory: Memory, albumServerId: Int, imageData: ByteArray): MemoryCreateResult {
        return try {
            val response = memoryGateway.uploadMemory(
                albumId = albumServerId,
                title = memory.title,
                imageRemoteUrl = null,
                fileData = imageData,
                fileName = MimeType.JPEG.fileName(memory.localId),
                mimeType = MimeType.JPEG.value
            )

            // Delete local image
            imageStorageRepository.delete(ImageEntityType.MEMORY, memory.localId)

            // Update local DB
            memoryRepository.markAsSynced(memory.localId, response.id)

            val syncedMemory = MemoryMapper.toDomain(response, memory.localId, memory.albumLocalId)
            if (syncedMemory != null) {
                MemoryCreateResult.Success(syncedMemory)
            } else {
                MemoryCreateResult.Success(memory.copy(serverId = response.id, syncStatus = SyncStatus.SYNCED))
            }
        } catch (e: Exception) {
            // Sync failed, enqueue for later
            syncQueueService.enqueue(EntityType.MEMORY, OperationType.CREATE, memory.localId)
            MemoryCreateResult.SuccessPendingSync(memory)
        }
    }
}
