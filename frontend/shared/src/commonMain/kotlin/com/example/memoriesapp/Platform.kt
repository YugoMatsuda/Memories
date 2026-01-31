package com.example.memoriesapp

interface Platform {
    val name: String
}

expect fun getPlatform(): Platform