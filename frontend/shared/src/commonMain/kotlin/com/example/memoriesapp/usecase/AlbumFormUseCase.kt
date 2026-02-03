package com.example.memoriesapp.usecase

import com.example.memoriesapp.domain.Album

/**
 * Result of album create operation
 */
sealed class AlbumCreateResult {
    data class Success(val album: Album) : AlbumCreateResult()
    data class SuccessPendingSync(val album: Album) : AlbumCreateResult()
    data class Failure(val error: AlbumCreateError) : AlbumCreateResult()
}

enum class AlbumCreateError {
    NETWORK_ERROR,
    SERVER_ERROR,
    IMAGE_STORAGE_FAILED,
    DATABASE_ERROR,
    UNKNOWN
}

/**
 * Result of album update operation
 */
sealed class AlbumUpdateResult {
    data class Success(val album: Album) : AlbumUpdateResult()
    data class SuccessPendingSync(val album: Album) : AlbumUpdateResult()
    data class Failure(val error: AlbumUpdateError) : AlbumUpdateResult()
}

enum class AlbumUpdateError {
    NETWORK_ERROR,
    SERVER_ERROR,
    NOT_FOUND,
    IMAGE_STORAGE_FAILED,
    DATABASE_ERROR,
    UNKNOWN
}

interface AlbumFormUseCase {
    suspend fun createAlbum(title: String, coverImageData: ByteArray?): AlbumCreateResult
    suspend fun updateAlbum(album: Album, title: String, coverImageData: ByteArray?): AlbumUpdateResult
}
