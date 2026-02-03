package com.example.memoriesapp.usecase.impl

import com.example.memoriesapp.domain.EntityType
import com.example.memoriesapp.domain.SyncOperation
import com.example.memoriesapp.repository.AlbumRepository
import com.example.memoriesapp.repository.MemoryRepository
import com.example.memoriesapp.repository.SyncQueueRepository
import com.example.memoriesapp.repository.UserRepository
import com.example.memoriesapp.usecase.SyncQueueItem
import com.example.memoriesapp.usecase.SyncQueuesUseCase
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

/**
 * UseCase for viewing the sync queue
 */
class SyncQueuesUseCaseImpl(
    private val syncQueueRepository: SyncQueueRepository,
    private val albumRepository: AlbumRepository,
    private val memoryRepository: MemoryRepository,
    private val userRepository: UserRepository
) : SyncQueuesUseCase {
    override fun observeState(): Flow<Unit> = syncQueueRepository.stateFlow.map { }

    override suspend fun getAll(): List<SyncQueueItem> {
        val operations = syncQueueRepository.getAll()

        return operations.map { operation ->
            val (title, serverId) = fetchEntityDetails(operation)
            SyncQueueItem(
                operation = operation,
                entityTitle = title,
                entityServerId = serverId
            )
        }
    }

    private suspend fun fetchEntityDetails(operation: SyncOperation): Pair<String?, Int?> {
        return when (operation.entityType) {
            EntityType.ALBUM -> {
                val album = albumRepository.getByLocalId(operation.localId)
                Pair(album?.title, album?.serverId)
            }
            EntityType.MEMORY -> {
                val memory = memoryRepository.getByLocalId(operation.localId)
                Pair(memory?.title, memory?.serverId)
            }
            EntityType.USER -> {
                val user = userRepository.get()
                Pair(user?.name, user?.id)
            }
        }
    }
}
