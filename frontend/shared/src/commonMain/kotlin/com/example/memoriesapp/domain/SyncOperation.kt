package com.example.memoriesapp.domain

import com.example.memoriesapp.core.LocalId
import com.example.memoriesapp.core.Timestamp
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

data class SyncOperation(
    val id: LocalId,
    val entityType: EntityType,
    val operationType: OperationType,
    val localId: LocalId,
    val createdAt: Timestamp,
    val status: SyncOperationStatus,
    val errorMessage: String? = null
)

@Serializable
enum class EntityType {
    @SerialName("album")
    ALBUM,

    @SerialName("memory")
    MEMORY,

    @SerialName("user")
    USER
}

@Serializable
enum class OperationType {
    @SerialName("create")
    CREATE,

    @SerialName("update")
    UPDATE
}

@Serializable
enum class SyncOperationStatus {
    @SerialName("pending")
    PENDING,

    @SerialName("inProgress")
    IN_PROGRESS,

    @SerialName("failed")
    FAILED
}
