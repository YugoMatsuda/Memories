package com.example.memoriesapp.usecase

import com.example.memoriesapp.domain.SyncOperation
import kotlinx.coroutines.flow.Flow

/**
 * Item representing a sync queue entry with entity details
 */
data class SyncQueueItem(
    val operation: SyncOperation,
    val entityTitle: String?,
    val entityServerId: Int?
)

interface SyncQueuesUseCase {
    fun observeState(): Flow<Unit>
    suspend fun getAll(): List<SyncQueueItem>
}
