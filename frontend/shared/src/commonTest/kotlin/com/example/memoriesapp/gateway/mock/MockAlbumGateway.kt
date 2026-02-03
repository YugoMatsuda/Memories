package com.example.memoriesapp.gateway.mock

import com.example.memoriesapp.api.error.ApiError
import com.example.memoriesapp.api.response.AlbumResponse
import com.example.memoriesapp.api.response.PaginatedAlbumsResponse
import com.example.memoriesapp.gateway.AlbumGateway

class MockAlbumGateway : AlbumGateway {
    private var albumResponse: AlbumResponse? = null
    private var paginatedResponse: PaginatedAlbumsResponse? = null
    private var errorToThrow: Exception? = null

    fun setAlbumResponse(response: AlbumResponse) {
        albumResponse = response
        errorToThrow = null
    }

    fun setPaginatedResponse(response: PaginatedAlbumsResponse) {
        paginatedResponse = response
        errorToThrow = null
    }

    fun setError(error: Exception) {
        errorToThrow = error
        albumResponse = null
        paginatedResponse = null
    }

    override suspend fun getAlbum(id: Int): AlbumResponse {
        errorToThrow?.let { throw it }
        return albumResponse ?: throw ApiError.NotFound
    }

    override suspend fun getAlbums(page: Int, pageSize: Int): PaginatedAlbumsResponse {
        errorToThrow?.let { throw it }
        return paginatedResponse ?: PaginatedAlbumsResponse(
            items = emptyList(),
            page = page,
            pageSize = pageSize,
            total = 0
        )
    }

    override suspend fun createAlbum(title: String, coverImageUrl: String?): AlbumResponse {
        errorToThrow?.let { throw it }
        return albumResponse ?: throw ApiError.Unexpected(null)
    }

    override suspend fun updateAlbum(albumId: Int, title: String?, coverImageUrl: String?): AlbumResponse {
        errorToThrow?.let { throw it }
        return albumResponse ?: throw ApiError.NotFound
    }

    override suspend fun uploadCoverImage(
        albumId: Int,
        fileData: ByteArray,
        fileName: String,
        mimeType: String
    ): AlbumResponse {
        errorToThrow?.let { throw it }
        return albumResponse ?: throw ApiError.NotFound
    }
}
