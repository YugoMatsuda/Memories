package com.example.memoriesapp.domain

import com.example.memoriesapp.core.SyncStatus
import kotlinx.datetime.LocalDate

data class User(
    val id: Int,
    val name: String,
    val username: String,
    val birthday: LocalDate?,
    val avatarUrl: String?,
    val avatarLocalPath: String? = null,
    val syncStatus: SyncStatus = SyncStatus.SYNCED
) {
    val isSynced: Boolean
        get() = syncStatus == SyncStatus.SYNCED

    val displayAvatar: String?
        get() = avatarUrl ?: avatarLocalPath
}
