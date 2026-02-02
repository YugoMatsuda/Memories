package com.example.memoriesapp.usecase

import com.example.memoriesapp.domain.Album

interface AlbumFormUseCase {
    suspend fun createAlbum(title: String, coverImageData: ByteArray?): AlbumCreateResult
    suspend fun updateAlbum(album: Album, title: String, coverImageData: ByteArray?): AlbumUpdateResult
}
