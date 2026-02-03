package com.example.memoriesapp.usecase.impl

import com.example.memoriesapp.repository.AuthSessionRepository
import com.example.memoriesapp.usecase.CheckPreviousSessionResult
import com.example.memoriesapp.usecase.DeepLink
import com.example.memoriesapp.usecase.HandleDeepLinkResult
import com.example.memoriesapp.usecase.RootUseCase
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.drop
import kotlinx.coroutines.flow.filter
import kotlinx.coroutines.flow.map

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
