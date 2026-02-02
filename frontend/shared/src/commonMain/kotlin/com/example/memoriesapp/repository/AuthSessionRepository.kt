package com.example.memoriesapp.repository

import com.example.memoriesapp.domain.AuthSession
import kotlinx.coroutines.flow.Flow

/**
 * Repository interface for authentication session management
 */
interface AuthSessionRepository {
    fun restore(): AuthSession?
    fun getSession(): AuthSession?
    val sessionFlow: Flow<AuthSession?>
    fun save(session: AuthSession)
    fun clearSession()
}
