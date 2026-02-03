package com.example.memoriesapp.gateway.impl

import com.example.memoriesapp.api.client.ApiClient
import com.example.memoriesapp.api.request.AlbumCoverUploadRequest
import com.example.memoriesapp.api.request.AlbumCreateRequest
import com.example.memoriesapp.api.request.AlbumUpdateRequest
import com.example.memoriesapp.api.request.GetAlbumRequest
import com.example.memoriesapp.api.request.GetAlbumsRequest
import com.example.memoriesapp.api.response.AlbumResponse
import com.example.memoriesapp.api.response.PaginatedAlbumsResponse
import com.example.memoriesapp.gateway.AlbumGateway
import kotlinx.serialization.json.Json

/**
 * Album gateway implementation
 */
class AlbumGatewayImpl(
    private val apiClient: ApiClient
) : AlbumGateway {
    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
    }

    override suspend fun getAlbum(id: Int): AlbumResponse {
        val request = GetAlbumRequest(albumId = id)
        val data = apiClient.sendRequest(request)
        return json.decodeFromString(AlbumResponse.serializer(), data.decodeToString())
    }

    override suspend fun getAlbums(page: Int, pageSize: Int): PaginatedAlbumsResponse {
        val request = GetAlbumsRequest(page = page, pageSize = pageSize)
        val data = apiClient.sendRequest(request)
        return json.decodeFromString(PaginatedAlbumsResponse.serializer(), data.decodeToString())
    }

    override suspend fun createAlbum(title: String, coverImageUrl: String?): AlbumResponse {
        val request = AlbumCreateRequest(title = title, coverImageUrl = coverImageUrl)
        val data = apiClient.sendRequest(request)
        return json.decodeFromString(AlbumResponse.serializer(), data.decodeToString())
    }

    override suspend fun updateAlbum(albumId: Int, title: String?, coverImageUrl: String?): AlbumResponse {
        val request = AlbumUpdateRequest(albumId = albumId, title = title, coverImageUrl = coverImageUrl)
        val data = apiClient.sendRequest(request)
        return json.decodeFromString(AlbumResponse.serializer(), data.decodeToString())
    }

    override suspend fun uploadCoverImage(
        albumId: Int,
        fileData: ByteArray,
        fileName: String,
        mimeType: String
    ): AlbumResponse {
        val request = AlbumCoverUploadRequest(
            albumId = albumId,
            fileData = fileData,
            fileName = fileName,
            mimeType = mimeType
        )
        val data = apiClient.sendRequest(request)
        return json.decodeFromString(AlbumResponse.serializer(), data.decodeToString())
    }
}
