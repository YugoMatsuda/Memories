package com.example.memoriesapp.usecase

import com.example.memoriesapp.domain.AuthSession
import com.example.memoriesapp.repository.AuthSessionRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.drop
import kotlinx.coroutines.flow.filter
import kotlinx.coroutines.flow.map

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

/**
 * Root UseCase for app-level operations
 */
class RootUseCaseImpl(
    private val authSessionRepository: AuthSessionRepository
) : RootUseCase {
    /**
     * Observe logout events (emits Unit when session becomes null after initial value)
     */
    override val observeDidLogout: Flow<Unit>
        get() = authSessionRepository.sessionFlow
            .drop(1) // Skip initial value
            .filter { it == null }
            .map { }

    /**
     * Check if there's a previous session stored
     */
    override fun checkPreviousSession(): CheckPreviousSessionResult {
        val session = authSessionRepository.restore()
        return if (session != null) {
            CheckPreviousSessionResult.LoggedIn(session)
        } else {
            CheckPreviousSessionResult.NotLoggedIn
        }
    }

    /**
     * Handle a deep link URL
     */
    override fun handleDeepLink(url: String): HandleDeepLinkResult {
        val deepLink = DeepLink.parse(url) ?: return HandleDeepLinkResult.InvalidURL

        return if (authSessionRepository.restore() != null) {
            HandleDeepLinkResult.Authenticated(deepLink)
        } else {
            HandleDeepLinkResult.NotAuthenticated(deepLink)
        }
    }
}
