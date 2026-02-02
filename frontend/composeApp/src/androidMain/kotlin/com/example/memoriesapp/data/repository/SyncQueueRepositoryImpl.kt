package com.example.memoriesapp.data.repository

import com.example.memoriesapp.core.LocalId
import com.example.memoriesapp.domain.SyncOperation
import com.example.memoriesapp.domain.SyncOperationStatus
import com.example.memoriesapp.repository.SyncQueueRepository
import com.example.memoriesapp.repository.SyncQueueState
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

/**
 * In-memory implementation of SyncQueueRepository.
 * No persistence - queue is lost on app restart.
 */
class SyncQueueRepositoryImpl : SyncQueueRepository {
    private val operations = mutableListOf<SyncOperation>()
    private val mutex = Mutex()
    private var isSyncing = false

    private val _stateFlow = MutableStateFlow(SyncQueueState(pendingCount = 0, isSyncing = false))
    override val stateFlow: Flow<SyncQueueState> = _stateFlow.asStateFlow()

    override suspend fun enqueue(operation: SyncOperation) {
        mutex.withLock {
            operations.add(operation)
            emitState()
        }
    }

    override suspend fun peek(): List<SyncOperation> {
        return mutex.withLock {
            operations.filter { it.status == SyncOperationStatus.PENDING }
        }
    }

    override suspend fun getAll(): List<SyncOperation> {
        return mutex.withLock {
            operations.toList()
        }
    }

    override suspend fun remove(id: LocalId) {
        mutex.withLock {
            operations.removeAll { it.id == id }
            emitState()
        }
    }

    override suspend fun updateStatus(id: LocalId, status: SyncOperationStatus, errorMessage: String?) {
        mutex.withLock {
            val index = operations.indexOfFirst { it.id == id }
            if (index >= 0) {
                operations[index] = operations[index].copy(
                    status = status,
                    errorMessage = errorMessage
                )
                emitState()
            }
        }
    }

    override fun tryStartSyncing(): Boolean {
        if (isSyncing) return false
        isSyncing = true
        _stateFlow.value = _stateFlow.value.copy(isSyncing = true)
        return true
    }

    override fun stopSyncing() {
        isSyncing = false
        _stateFlow.value = _stateFlow.value.copy(isSyncing = false)
    }

    override suspend fun refreshState() {
        mutex.withLock {
            emitState()
        }
    }

    private fun emitState() {
        val pendingCount = operations.count { it.status == SyncOperationStatus.PENDING }
        _stateFlow.value = SyncQueueState(pendingCount = pendingCount, isSyncing = isSyncing)
    }
}
