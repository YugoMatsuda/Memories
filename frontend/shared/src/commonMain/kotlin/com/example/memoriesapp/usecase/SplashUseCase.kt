package com.example.memoriesapp.usecase

interface SplashUseCase {
    suspend fun launchApp(): LaunchAppResult
    fun clearSession()
}
