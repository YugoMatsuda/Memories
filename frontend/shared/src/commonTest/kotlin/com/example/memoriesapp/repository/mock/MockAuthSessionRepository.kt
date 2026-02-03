package com.example.memoriesapp.repository.mock

import com.example.memoriesapp.domain.AuthSession
import com.example.memoriesapp.repository.AuthSessionRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow

class MockAuthSessionRepository : AuthSessionRepository {
    private val sessionState = MutableStateFlow<AuthSession?>(null)
    private var savedSession: AuthSession? = null

    override fun restore(): AuthSession? = savedSession

    override fun getSession(): AuthSession? = savedSession

    override val sessionFlow: Flow<AuthSession?> = sessionState

    override fun save(session: AuthSession) {
        savedSession = session
        sessionState.value = session
    }

    override fun clearSession() {
        savedSession = null
        sessionState.value = null
    }

    // Test helpers
    fun getSavedSession(): AuthSession? = savedSession
}
