package com.example.memoriesapp.repository

import com.example.memoriesapp.core.LocalId
import com.example.memoriesapp.domain.Memory
import kotlinx.coroutines.flow.Flow

/**
 * Event fired when a local memory change occurs
 */
sealed class LocalMemoryChangeEvent {
    data class Created(val memory: Memory) : LocalMemoryChangeEvent()
}

/**
 * Repository interface for Memory data
 */
interface MemoryRepository {
    // Read
    suspend fun getAll(albumLocalId: LocalId): List<Memory>
    suspend fun getByLocalId(localId: LocalId): Memory?

    // Server Sync (no event firing)
    suspend fun syncSet(memories: List<Memory>, albumLocalId: LocalId)
    suspend fun syncAppend(memories: List<Memory>)

    // Local Operations (fires events)
    suspend fun insert(memory: Memory)

    // Sync Status
    suspend fun markAsSynced(localId: LocalId, serverId: Int)

    // Change Flow
    val localChangeFlow: Flow<LocalMemoryChangeEvent>
}
