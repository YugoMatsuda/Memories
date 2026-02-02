package com.example.memoriesapp.data.repository

import com.example.memoriesapp.domain.User
import com.example.memoriesapp.repository.UserRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.asSharedFlow

/**
 * In-memory implementation of UserRepository.
 * No persistence - data is lost on app restart.
 */
class UserRepositoryImpl(
    override val userId: Int
) : UserRepository {
    private var user: User? = null
    private val _userFlow = MutableSharedFlow<User>(replay = 1)

    override val userFlow: Flow<User> = _userFlow.asSharedFlow()

    override suspend fun get(): User? = user

    override suspend fun set(user: User) {
        this.user = user
        _userFlow.emit(user)
    }

    override fun notify(user: User) {
        _userFlow.tryEmit(user)
    }
}
