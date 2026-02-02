package com.example.memoriesapp.repository

import com.example.memoriesapp.core.LocalId
import com.example.memoriesapp.domain.SyncOperation
import com.example.memoriesapp.domain.SyncOperationStatus
import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow

/**
 * Callback interface for sync queue state changes
 */
interface SyncQueueStateCallback {
    fun onStateChanged(state: SyncQueueState)
}

/**
 * Bridge interface for Swift to implement
 */
interface SyncQueueRepositoryBridge {
    suspend fun enqueue(operation: SyncOperation)
    suspend fun peek(): List<SyncOperation>
    suspend fun getAll(): List<SyncOperation>
    suspend fun remove(id: LocalId)
    suspend fun updateStatus(id: LocalId, status: SyncOperationStatus, errorMessage: String?)
    fun tryStartSyncing(): Boolean
    fun stopSyncing()
    suspend fun refreshState()
    fun registerStateCallback(callback: SyncQueueStateCallback)
    fun unregisterStateCallback()
}

/**
 * iOS implementation of SyncQueueRepository
 */
class SyncQueueRepositoryImpl(
    private val bridge: SyncQueueRepositoryBridge
) : SyncQueueRepository {

    private val _stateFlow = MutableSharedFlow<SyncQueueState>(
        replay = 1,
        extraBufferCapacity = 64,
        onBufferOverflow = BufferOverflow.DROP_OLDEST
    )

    override val stateFlow: SharedFlow<SyncQueueState> = _stateFlow.asSharedFlow()

    init {
        bridge.registerStateCallback(object : SyncQueueStateCallback {
            override fun onStateChanged(state: SyncQueueState) {
                _stateFlow.tryEmit(state)
            }
        })
    }

    override suspend fun enqueue(operation: SyncOperation) = bridge.enqueue(operation)

    override suspend fun peek(): List<SyncOperation> = bridge.peek()

    override suspend fun getAll(): List<SyncOperation> = bridge.getAll()

    override suspend fun remove(id: LocalId) = bridge.remove(id)

    override suspend fun updateStatus(id: LocalId, status: SyncOperationStatus, errorMessage: String?) =
        bridge.updateStatus(id, status, errorMessage)

    override fun tryStartSyncing(): Boolean = bridge.tryStartSyncing()

    override fun stopSyncing() = bridge.stopSyncing()

    override suspend fun refreshState() = bridge.refreshState()
}
