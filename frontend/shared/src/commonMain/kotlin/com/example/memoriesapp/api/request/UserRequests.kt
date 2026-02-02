package com.example.memoriesapp.api.request

import com.example.memoriesapp.api.client.*
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Get current user
 * GET /me
 */
data object GetUserRequest : ApiRequest {
    override val path: String = "/me"
    override val method: HttpMethod = HttpMethod.GET
}

/**
 * Update user profile
 * PUT /me
 */
data class UserUpdateRequest(
    val name: String? = null,
    val birthday: String? = null,
    val avatarUrl: String? = null
) : ApiRequest {
    override val path: String = "/me"
    override val method: HttpMethod = HttpMethod.PUT
    override val body: Any = UserUpdateBody(name, birthday, avatarUrl)
}

@Serializable
internal data class UserUpdateBody(
    val name: String? = null,
    val birthday: String? = null,
    @SerialName("avatar_url")
    val avatarUrl: String? = null
)

/**
 * Upload avatar image
 * POST /me/avatar (multipart)
 */
data class AvatarUploadRequest(
    val fileData: ByteArray,
    val fileName: String,
    val mimeType: String
) : MultipartApiRequest {
    override val path: String = "/me/avatar"
    override val method: HttpMethod = HttpMethod.POST
    override val fileFields: List<MultipartFileField> = listOf(
        MultipartFileField(
            name = "file",
            fileName = fileName,
            contentType = mimeType,
            data = fileData
        )
    )

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other == null || this::class != other::class) return false
        other as AvatarUploadRequest
        if (!fileData.contentEquals(other.fileData)) return false
        if (fileName != other.fileName) return false
        if (mimeType != other.mimeType) return false
        return true
    }

    override fun hashCode(): Int {
        var result = fileData.contentHashCode()
        result = 31 * result + fileName.hashCode()
        result = 31 * result + mimeType.hashCode()
        return result
    }
}
