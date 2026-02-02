package com.example.memoriesapp.repository

import com.example.memoriesapp.core.LocalId
import com.example.memoriesapp.domain.SyncOperationStatus
import com.example.memoriesapp.domain.SyncOperation
import kotlinx.coroutines.flow.Flow

/**
 * State of the sync queue
 */
data class SyncQueueState(
    val pendingCount: Int,
    val isSyncing: Boolean
)

/**
 * Repository interface for SyncQueue operations
 */
interface SyncQueueRepository {
    suspend fun enqueue(operation: SyncOperation)
    suspend fun peek(): List<SyncOperation>
    suspend fun getAll(): List<SyncOperation>
    suspend fun remove(id: LocalId)
    suspend fun updateStatus(id: LocalId, status: SyncOperationStatus, errorMessage: String?)
    fun tryStartSyncing(): Boolean
    fun stopSyncing()
    suspend fun refreshState()
    val stateFlow: Flow<SyncQueueState>
}
