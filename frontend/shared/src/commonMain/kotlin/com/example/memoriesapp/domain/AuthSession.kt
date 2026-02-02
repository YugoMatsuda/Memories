package com.example.memoriesapp.domain

data class AuthSession(
    val token: String,
    val userId: Int
)
