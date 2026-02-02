package com.example.memoriesapp.data.repository

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import com.example.memoriesapp.domain.AuthSession
import com.example.memoriesapp.repository.AuthSessionRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Secure implementation of AuthSessionRepository using EncryptedSharedPreferences.
 */
class AuthSessionRepositoryImpl(
    context: Context
) : AuthSessionRepository {

    private val _sessionFlow = MutableStateFlow<AuthSession?>(null)

    private val encryptedPrefs: SharedPreferences by lazy {
        val masterKey = MasterKey.Builder(context)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()

        EncryptedSharedPreferences.create(
            context,
            PREFS_FILE_NAME,
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
        )
    }

    override val sessionFlow: Flow<AuthSession?> = _sessionFlow.asStateFlow()

    override fun restore(): AuthSession? {
        val token = encryptedPrefs.getString(KEY_ACCESS_TOKEN, null)
        val userId = encryptedPrefs.getInt(KEY_USER_ID, -1)

        if (token == null || userId == -1) {
            return null
        }

        val session = AuthSession(token = token, userId = userId)
        _sessionFlow.value = session
        return session
    }

    override fun getSession(): AuthSession? = _sessionFlow.value

    override fun save(session: AuthSession) {
        encryptedPrefs.edit()
            .putString(KEY_ACCESS_TOKEN, session.token)
            .putInt(KEY_USER_ID, session.userId)
            .apply()

        _sessionFlow.value = session
    }

    override fun clearSession() {
        encryptedPrefs.edit()
            .remove(KEY_ACCESS_TOKEN)
            .remove(KEY_USER_ID)
            .apply()

        _sessionFlow.value = null
    }

    companion object {
        private const val PREFS_FILE_NAME = "memories_auth_prefs"
        private const val KEY_ACCESS_TOKEN = "access_token"
        private const val KEY_USER_ID = "user_id"
    }
}
