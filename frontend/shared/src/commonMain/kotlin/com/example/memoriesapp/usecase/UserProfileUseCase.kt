package com.example.memoriesapp.usecase

import kotlinx.datetime.LocalDate

interface UserProfileUseCase {
    suspend fun updateProfile(name: String, birthday: LocalDate?, avatarData: ByteArray?): UpdateProfileResult
    fun logout()
}
