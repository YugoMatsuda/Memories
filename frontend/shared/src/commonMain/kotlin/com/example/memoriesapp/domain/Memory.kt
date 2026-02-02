package com.example.memoriesapp.domain

import com.example.memoriesapp.core.LocalId
import com.example.memoriesapp.core.SyncStatus
import com.example.memoriesapp.core.Timestamp

data class Memory(
    val serverId: Int?,
    val localId: LocalId,
    val albumId: Int?,
    val albumLocalId: LocalId,
    val title: String,
    val imageUrl: String?,
    val imageLocalPath: String?,
    val createdAt: Timestamp,
    val syncStatus: SyncStatus = SyncStatus.SYNCED
) {
    val isSynced: Boolean
        get() = syncStatus == SyncStatus.SYNCED

    val displayImage: String?
        get() = imageUrl ?: imageLocalPath
}
