package com.example.memoriesapp.gateway

import com.example.memoriesapp.api.response.AlbumResponse
import com.example.memoriesapp.api.response.PaginatedAlbumsResponse

/**
 * Album gateway interface
 */
interface AlbumGateway {
    suspend fun getAlbum(id: Int): AlbumResponse
    suspend fun getAlbums(page: Int, pageSize: Int): PaginatedAlbumsResponse
    suspend fun createAlbum(title: String, coverImageUrl: String?): AlbumResponse
    suspend fun updateAlbum(albumId: Int, title: String?, coverImageUrl: String?): AlbumResponse
    suspend fun uploadCoverImage(albumId: Int, fileData: ByteArray, fileName: String, mimeType: String): AlbumResponse
}
