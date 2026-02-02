package com.example.memoriesapp.core

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
enum class SyncStatus {
    @SerialName("synced")
    SYNCED,

    @SerialName("pendingCreate")
    PENDING_CREATE,

    @SerialName("pendingUpdate")
    PENDING_UPDATE,

    @SerialName("syncing")
    SYNCING,

    @SerialName("failed")
    FAILED
}
