package com.example.memoriesapp.usecase

import com.example.memoriesapp.core.LocalId
import com.example.memoriesapp.domain.EntityType
import com.example.memoriesapp.domain.OperationType

interface SyncQueueService {
    fun enqueue(entityType: EntityType, operationType: OperationType, localId: LocalId)
    suspend fun processQueue()
}
