package com.example.memoriesapp.usecase.mock

import com.example.memoriesapp.core.LocalId
import com.example.memoriesapp.domain.EntityType
import com.example.memoriesapp.domain.OperationType
import com.example.memoriesapp.usecase.SyncQueueService

class MockSyncQueueService : SyncQueueService {
    var processQueueCallCount = 0
        private set

    private val enqueuedOperations = mutableListOf<Triple<EntityType, OperationType, LocalId>>()

    override fun enqueue(entityType: EntityType, operationType: OperationType, localId: LocalId) {
        enqueuedOperations.add(Triple(entityType, operationType, localId))
    }

    override suspend fun processQueue() {
        processQueueCallCount++
    }

    // Test helpers
    fun reset() {
        processQueueCallCount = 0
        enqueuedOperations.clear()
    }

    fun getEnqueuedOperations(): List<Triple<EntityType, OperationType, LocalId>> =
        enqueuedOperations.toList()
}
