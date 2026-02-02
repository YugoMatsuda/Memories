package com.example.memoriesapp.usecase

interface LoginUseCase {
    suspend fun login(username: String, password: String): LoginResult
}
