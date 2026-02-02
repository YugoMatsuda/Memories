package com.example.memoriesapp.domain

import com.example.memoriesapp.core.LocalId
import com.example.memoriesapp.core.SyncStatus
import com.example.memoriesapp.core.Timestamp

data class Album(
    val serverId: Int?,
    val localId: LocalId,
    val title: String,
    val coverImageUrl: String?,
    val coverImageLocalPath: String?,
    val createdAt: Timestamp,
    val syncStatus: SyncStatus
) {
    val isSynced: Boolean
        get() = serverId != null && syncStatus == SyncStatus.SYNCED

    val displayCoverImage: String?
        get() = coverImageUrl ?: coverImageLocalPath
}
