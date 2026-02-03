package com.example.memoriesapp.usecase

import com.example.memoriesapp.domain.User
import kotlinx.datetime.LocalDate

/**
 * Result of profile update operation
 */
sealed class UpdateProfileResult {
    data class Success(val user: User) : UpdateProfileResult()
    data class SuccessPendingSync(val user: User) : UpdateProfileResult()
    data class Failure(val error: UpdateProfileError) : UpdateProfileResult()
}

enum class UpdateProfileError {
    NETWORK_ERROR,
    SERVER_ERROR,
    IMAGE_STORAGE_FAILED,
    DATABASE_ERROR,
    UNKNOWN
}

interface UserProfileUseCase {
    suspend fun updateProfile(name: String, birthday: LocalDate?, avatarData: ByteArray?): UpdateProfileResult
    fun logout()
}
