package com.example.memoriesapp.data.repository

import com.example.memoriesapp.core.LocalId
import com.example.memoriesapp.core.SyncStatus
import com.example.memoriesapp.domain.Memory
import com.example.memoriesapp.repository.LocalMemoryChangeEvent
import com.example.memoriesapp.repository.MemoryRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.asSharedFlow

/**
 * In-memory implementation of MemoryRepository.
 * No persistence - data is lost on app restart.
 */
class MemoryRepositoryImpl : MemoryRepository {
    private val memories = mutableListOf<Memory>()
    private val _localChangeFlow = MutableSharedFlow<LocalMemoryChangeEvent>()

    override val localChangeFlow: Flow<LocalMemoryChangeEvent> = _localChangeFlow.asSharedFlow()

    override suspend fun getAll(albumLocalId: LocalId): List<Memory> =
        memories.filter { it.albumLocalId == albumLocalId }

    override suspend fun getByLocalId(localId: LocalId): Memory? =
        memories.find { it.localId == localId }

    override suspend fun syncSet(memories: List<Memory>, albumLocalId: LocalId) {
        this.memories.removeAll { it.albumLocalId == albumLocalId }
        this.memories.addAll(memories)
    }

    override suspend fun syncAppend(memories: List<Memory>) {
        memories.forEach { memory ->
            val index = this.memories.indexOfFirst { it.localId == memory.localId }
            if (index >= 0) {
                this.memories[index] = memory
            } else {
                this.memories.add(memory)
            }
        }
    }

    override suspend fun insert(memory: Memory) {
        memories.add(0, memory)
        _localChangeFlow.emit(LocalMemoryChangeEvent.Created(memory))
    }

    override suspend fun markAsSynced(localId: LocalId, serverId: Int) {
        val index = memories.indexOfFirst { it.localId == localId }
        if (index >= 0) {
            memories[index] = memories[index].copy(
                serverId = serverId,
                syncStatus = SyncStatus.SYNCED
            )
        }
    }
}
