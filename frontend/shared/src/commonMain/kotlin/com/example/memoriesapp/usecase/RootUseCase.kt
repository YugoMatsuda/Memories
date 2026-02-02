package com.example.memoriesapp.usecase

import kotlinx.coroutines.flow.Flow

interface RootUseCase {
    val observeDidLogout: Flow<Unit>
    fun checkPreviousSession(): CheckPreviousSessionResult
    fun handleDeepLink(url: String): HandleDeepLinkResult
}
