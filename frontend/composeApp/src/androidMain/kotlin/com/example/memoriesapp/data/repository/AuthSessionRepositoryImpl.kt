package com.example.memoriesapp.data.repository

import com.example.memoriesapp.domain.AuthSession
import com.example.memoriesapp.repository.AuthSessionRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * In-memory implementation of AuthSessionRepository.
 * No persistence - session is lost on app restart.
 */
class AuthSessionRepositoryImpl : AuthSessionRepository {
    private val _sessionFlow = MutableStateFlow<AuthSession?>(null)

    override val sessionFlow: Flow<AuthSession?> = _sessionFlow.asStateFlow()

    override fun restore(): AuthSession? = _sessionFlow.value

    override fun getSession(): AuthSession? = _sessionFlow.value

    override fun save(session: AuthSession) {
        _sessionFlow.value = session
    }

    override fun clearSession() {
        _sessionFlow.value = null
    }
}
