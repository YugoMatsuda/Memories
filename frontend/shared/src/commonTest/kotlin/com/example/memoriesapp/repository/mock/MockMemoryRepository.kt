package com.example.memoriesapp.repository.mock

import com.example.memoriesapp.core.LocalId
import com.example.memoriesapp.domain.Memory
import com.example.memoriesapp.repository.LocalMemoryChangeEvent
import com.example.memoriesapp.repository.MemoryRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow

class MockMemoryRepository : MemoryRepository {
    private val memories = mutableListOf<Memory>()
    private val _localChangeFlow = MutableSharedFlow<LocalMemoryChangeEvent>()

    override val localChangeFlow: Flow<LocalMemoryChangeEvent> = _localChangeFlow

    override suspend fun getAll(albumLocalId: LocalId): List<Memory> =
        memories.filter { it.albumLocalId == albumLocalId }

    override suspend fun getByLocalId(localId: LocalId): Memory? =
        memories.find { it.localId == localId }

    override suspend fun syncSet(memories: List<Memory>, albumLocalId: LocalId) {
        this.memories.removeAll { it.albumLocalId == albumLocalId }
        this.memories.addAll(memories)
    }

    override suspend fun syncAppend(memories: List<Memory>) {
        memories.forEach { newMemory ->
            val existingIndex = this.memories.indexOfFirst { it.serverId == newMemory.serverId }
            if (existingIndex >= 0) {
                this.memories[existingIndex] = newMemory
            } else {
                this.memories.add(newMemory)
            }
        }
    }

    override suspend fun insert(memory: Memory) {
        memories.add(memory)
        _localChangeFlow.emit(LocalMemoryChangeEvent.Created(memory))
    }

    override suspend fun markAsSynced(localId: LocalId, serverId: Int) {
        val index = memories.indexOfFirst { it.localId == localId }
        if (index >= 0) {
            memories[index] = memories[index].copy(serverId = serverId)
        }
    }

    // Test helpers
    fun setMemories(memories: List<Memory>) {
        this.memories.clear()
        this.memories.addAll(memories)
    }

    fun getMemories(): List<Memory> = memories.toList()
}
