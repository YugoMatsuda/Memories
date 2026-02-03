package com.example.memoriesapp.repository.mock

import com.example.memoriesapp.core.SyncStatus
import com.example.memoriesapp.domain.User
import com.example.memoriesapp.repository.UserRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow

class MockUserRepository(
    override val userId: Int = 1
) : UserRepository {
    private var user: User? = null
    private val _userFlow = MutableStateFlow(createDefaultUser())

    override val userFlow: Flow<User> = _userFlow

    override suspend fun get(): User? = user

    override suspend fun set(user: User) {
        this.user = user
        _userFlow.value = user
    }

    override fun notify(user: User) {
        _userFlow.value = user
    }

    // Test helpers
    fun setUser(user: User) {
        this.user = user
        _userFlow.value = user
    }

    private fun createDefaultUser() = User(
        id = userId,
        name = "Test User",
        username = "testuser",
        birthday = null,
        avatarUrl = null,
        syncStatus = SyncStatus.SYNCED
    )
}
