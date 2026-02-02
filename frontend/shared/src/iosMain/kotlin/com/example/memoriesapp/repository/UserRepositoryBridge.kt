package com.example.memoriesapp.repository

import com.example.memoriesapp.domain.User
import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow

/**
 * Callback interface for user updates
 */
interface UserChangeCallback {
    fun onUserChanged(user: User)
}

/**
 * Bridge interface for Swift to implement
 */
interface UserRepositoryBridge {
    val userId: Int
    suspend fun get(): User?
    suspend fun set(user: User)
    fun notify(user: User)
    fun registerChangeCallback(callback: UserChangeCallback)
    fun unregisterChangeCallback()
}

/**
 * iOS implementation of UserRepository
 */
class UserRepositoryImpl(
    private val bridge: UserRepositoryBridge
) : UserRepository {

    private val _userFlow = MutableSharedFlow<User>(
        replay = 1,
        extraBufferCapacity = 64,
        onBufferOverflow = BufferOverflow.DROP_OLDEST
    )

    override val userFlow: SharedFlow<User> = _userFlow.asSharedFlow()

    init {
        bridge.registerChangeCallback(object : UserChangeCallback {
            override fun onUserChanged(user: User) {
                _userFlow.tryEmit(user)
            }
        })
    }

    override val userId: Int get() = bridge.userId

    override suspend fun get(): User? = bridge.get()

    override suspend fun set(user: User) = bridge.set(user)

    override fun notify(user: User) = bridge.notify(user)
}
