package com.example.memoriesapp.repository.mock

import com.example.memoriesapp.core.LocalId
import com.example.memoriesapp.domain.SyncOperation
import com.example.memoriesapp.domain.SyncOperationStatus
import com.example.memoriesapp.repository.SyncQueueRepository
import com.example.memoriesapp.repository.SyncQueueState
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow

class MockSyncQueueRepository : SyncQueueRepository {
    private val operations = mutableListOf<SyncOperation>()
    private val _stateFlow = MutableStateFlow(SyncQueueState(pendingCount = 0, isSyncing = false))
    private var isSyncing = false

    override val stateFlow: Flow<SyncQueueState> = _stateFlow

    override suspend fun enqueue(operation: SyncOperation) {
        operations.add(operation)
        updateState()
    }

    override suspend fun peek(): List<SyncOperation> = operations.toList()

    override suspend fun getAll(): List<SyncOperation> = operations.toList()

    override suspend fun remove(id: LocalId) {
        operations.removeAll { it.id == id }
        updateState()
    }

    override suspend fun updateStatus(id: LocalId, status: SyncOperationStatus, errorMessage: String?) {
        val index = operations.indexOfFirst { it.id == id }
        if (index >= 0) {
            operations[index] = operations[index].copy(status = status, errorMessage = errorMessage)
        }
    }

    override fun tryStartSyncing(): Boolean {
        if (isSyncing) return false
        isSyncing = true
        updateState()
        return true
    }

    override fun stopSyncing() {
        isSyncing = false
        updateState()
    }

    override suspend fun refreshState() {
        updateState()
    }

    private fun updateState() {
        _stateFlow.value = SyncQueueState(
            pendingCount = operations.size,
            isSyncing = isSyncing
        )
    }

    // Test helpers
    fun setState(state: SyncQueueState) {
        _stateFlow.value = state
    }
}
