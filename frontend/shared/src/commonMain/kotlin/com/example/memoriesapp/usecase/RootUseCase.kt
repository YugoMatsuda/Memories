package com.example.memoriesapp.usecase

import com.example.memoriesapp.domain.AuthSession
import kotlinx.coroutines.flow.Flow

/**
 * Result of checking previous session
 */
sealed class CheckPreviousSessionResult {
    data class LoggedIn(val session: AuthSession) : CheckPreviousSessionResult()
    data object NotLoggedIn : CheckPreviousSessionResult()
}

/**
 * Result of handling deep link
 */
sealed class HandleDeepLinkResult {
    data class Authenticated(val deepLink: DeepLink) : HandleDeepLinkResult()
    data class NotAuthenticated(val deepLink: DeepLink) : HandleDeepLinkResult()
    data object InvalidURL : HandleDeepLinkResult()
}

interface RootUseCase {
    val observeDidLogout: Flow<Unit>
    fun checkPreviousSession(): CheckPreviousSessionResult
    fun handleDeepLink(url: String): HandleDeepLinkResult
}
