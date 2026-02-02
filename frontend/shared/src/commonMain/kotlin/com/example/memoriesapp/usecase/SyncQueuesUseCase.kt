package com.example.memoriesapp.usecase

import kotlinx.coroutines.flow.Flow

interface SyncQueuesUseCase {
    fun observeState(): Flow<Unit>
    suspend fun getAll(): List<SyncQueueItem>
}
