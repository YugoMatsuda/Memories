package com.example.memoriesapp.api.response

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Login response
 */
@Serializable
data class TokenResponse(
    val token: String,
    @SerialName("user_id")
    val userId: Int
)

/**
 * User response
 */
@Serializable
data class UserResponse(
    val id: Int,
    val name: String,
    val username: String,
    val birthday: String? = null,
    @SerialName("avatar_url")
    val avatarUrl: String? = null
)

/**
 * Album response
 */
@Serializable
data class AlbumResponse(
    val id: Int,
    val title: String,
    @SerialName("cover_image_url")
    val coverImageUrl: String? = null,
    @SerialName("created_at")
    val createdAt: String
)

/**
 * Memory response
 */
@Serializable
data class MemoryResponse(
    val id: Int,
    @SerialName("album_id")
    val albumId: Int,
    val title: String,
    @SerialName("image_local_uri")
    val imageLocalUri: String? = null,
    @SerialName("image_remote_url")
    val imageRemoteUrl: String? = null,
    @SerialName("created_at")
    val createdAt: String
)

/**
 * Paginated albums response
 */
@Serializable
data class PaginatedAlbumsResponse(
    val items: List<AlbumResponse>,
    val page: Int,
    @SerialName("page_size")
    val pageSize: Int,
    val total: Int
)

/**
 * Paginated memories response
 */
@Serializable
data class PaginatedMemoriesResponse(
    val items: List<MemoryResponse>,
    val page: Int,
    @SerialName("page_size")
    val pageSize: Int,
    val total: Int
)
