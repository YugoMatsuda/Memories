package com.example.memoriesapp.repository

import com.example.memoriesapp.core.LocalId
import com.example.memoriesapp.domain.Memory
import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow

/**
 * Callback interface for memory change events
 */
interface MemoryChangeCallback {
    fun onCreated(memory: Memory)
}

/**
 * Bridge interface for Swift to implement
 */
interface MemoryRepositoryBridge {
    suspend fun getAll(albumLocalId: LocalId): List<Memory>
    suspend fun getByLocalId(localId: LocalId): Memory?
    suspend fun syncSet(memories: List<Memory>, albumLocalId: LocalId)
    suspend fun syncAppend(memories: List<Memory>)
    suspend fun insert(memory: Memory)
    suspend fun markAsSynced(localId: LocalId, serverId: Int)
    fun registerChangeCallback(callback: MemoryChangeCallback)
    fun unregisterChangeCallback()
}

/**
 * iOS implementation of MemoryRepository
 */
class MemoryRepositoryImpl(
    private val bridge: MemoryRepositoryBridge
) : MemoryRepository {

    private val _localChangeFlow = MutableSharedFlow<LocalMemoryChangeEvent>(
        extraBufferCapacity = 64,
        onBufferOverflow = BufferOverflow.DROP_OLDEST
    )

    override val localChangeFlow: SharedFlow<LocalMemoryChangeEvent> = _localChangeFlow.asSharedFlow()

    init {
        bridge.registerChangeCallback(object : MemoryChangeCallback {
            override fun onCreated(memory: Memory) {
                _localChangeFlow.tryEmit(LocalMemoryChangeEvent.Created(memory))
            }
        })
    }

    override suspend fun getAll(albumLocalId: LocalId): List<Memory> =
        bridge.getAll(albumLocalId)

    override suspend fun getByLocalId(localId: LocalId): Memory? =
        bridge.getByLocalId(localId)

    override suspend fun syncSet(memories: List<Memory>, albumLocalId: LocalId) =
        bridge.syncSet(memories, albumLocalId)

    override suspend fun syncAppend(memories: List<Memory>) =
        bridge.syncAppend(memories)

    override suspend fun insert(memory: Memory) =
        bridge.insert(memory)

    override suspend fun markAsSynced(localId: LocalId, serverId: Int) =
        bridge.markAsSynced(localId, serverId)
}
