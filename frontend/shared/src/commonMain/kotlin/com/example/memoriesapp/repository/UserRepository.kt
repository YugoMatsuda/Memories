package com.example.memoriesapp.repository

import com.example.memoriesapp.domain.User
import kotlinx.coroutines.flow.Flow

/**
 * Repository interface for User data
 */
interface UserRepository {
    val userId: Int

    // Read
    suspend fun get(): User?

    // Write (always fires event)
    suspend fun set(user: User)

    // Notify (fires event without writing to DB)
    fun notify(user: User)

    // Flow
    val userFlow: Flow<User>
}
