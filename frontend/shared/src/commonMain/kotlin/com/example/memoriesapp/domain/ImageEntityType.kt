package com.example.memoriesapp.domain

/**
 * Type of image entity for storage organization
 */
enum class ImageEntityType(val path: String) {
    ALBUM_COVER("albums"),
    MEMORY("memories"),
    AVATAR("avatars")
}
