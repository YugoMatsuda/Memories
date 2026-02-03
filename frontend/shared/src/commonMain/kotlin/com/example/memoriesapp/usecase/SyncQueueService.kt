package com.example.memoriesapp.usecase

import com.example.memoriesapp.core.LocalId
import com.example.memoriesapp.domain.EntityType
import com.example.memoriesapp.domain.OperationType

/**
 * Sync errors
 */
sealed class SyncError : Exception() {
    data object DependencyNotSynced : SyncError()
    data object EntityNotFound : SyncError()
    data object ImageNotFound : SyncError()
}

interface SyncQueueService {
    fun enqueue(entityType: EntityType, operationType: OperationType, localId: LocalId)
    suspend fun processQueue()
}
