package com.example.memoriesapp.repository

import com.example.memoriesapp.domain.AuthSession
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow

/**
 * Callback interface for session changes
 */
interface SessionChangeCallback {
    fun onSessionChanged(session: AuthSession?)
}

/**
 * Bridge interface for Swift to implement
 */
interface AuthSessionRepositoryBridge {
    fun restore(): AuthSession?
    fun getSession(): AuthSession?
    fun save(session: AuthSession)
    fun clearSession()
    fun registerSessionCallback(callback: SessionChangeCallback)
    fun unregisterSessionCallback()
}

/**
 * iOS implementation of AuthSessionRepository
 */
class AuthSessionRepositoryImpl(
    private val bridge: AuthSessionRepositoryBridge
) : AuthSessionRepository {

    override fun restore(): AuthSession? = bridge.restore()

    override fun getSession(): AuthSession? = bridge.getSession()

    override fun save(session: AuthSession) = bridge.save(session)

    override fun clearSession() = bridge.clearSession()

    override val sessionFlow: Flow<AuthSession?> = callbackFlow {
        val callback = object : SessionChangeCallback {
            override fun onSessionChanged(session: AuthSession?) {
                trySend(session)
            }
        }
        bridge.registerSessionCallback(callback)
        awaitClose { bridge.unregisterSessionCallback() }
    }
}
