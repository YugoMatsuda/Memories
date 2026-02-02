package com.example.memoriesapp.api.request

import com.example.memoriesapp.api.client.*
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Get single album
 * GET /albums/{albumId}
 */
data class GetAlbumRequest(
    val albumId: Int
) : ApiRequest {
    override val path: String = "/albums/$albumId"
    override val method: HttpMethod = HttpMethod.GET
}

/**
 * Get paginated albums list
 * GET /albums?page=X&page_size=Y
 */
data class GetAlbumsRequest(
    val page: Int = 1,
    val pageSize: Int = 20
) : ApiRequest {
    override val path: String = "/albums"
    override val method: HttpMethod = HttpMethod.GET
    override val queryParams: Map<String, String> = mapOf(
        "page" to page.toString(),
        "page_size" to pageSize.toString()
    )
}

/**
 * Create new album
 * POST /albums
 */
data class AlbumCreateRequest(
    val title: String,
    val coverImageUrl: String? = null
) : ApiRequest {
    override val path: String = "/albums"
    override val method: HttpMethod = HttpMethod.POST
    override val body: Any = AlbumCreateBody(title, coverImageUrl)
}

@Serializable
internal data class AlbumCreateBody(
    val title: String,
    @SerialName("cover_image_url")
    val coverImageUrl: String? = null
)

/**
 * Update album
 * PUT /albums/{albumId}
 */
data class AlbumUpdateRequest(
    val albumId: Int,
    val title: String? = null,
    val coverImageUrl: String? = null
) : ApiRequest {
    override val path: String = "/albums/$albumId"
    override val method: HttpMethod = HttpMethod.PUT
    override val body: Any = AlbumUpdateBody(title, coverImageUrl)
}

@Serializable
internal data class AlbumUpdateBody(
    val title: String? = null,
    @SerialName("cover_image_url")
    val coverImageUrl: String? = null
)

/**
 * Upload album cover image
 * POST /albums/{albumId}/cover (multipart)
 */
data class AlbumCoverUploadRequest(
    val albumId: Int,
    val fileData: ByteArray,
    val fileName: String,
    val mimeType: String
) : MultipartApiRequest {
    override val path: String = "/albums/$albumId/cover"
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
        other as AlbumCoverUploadRequest
        if (albumId != other.albumId) return false
        if (!fileData.contentEquals(other.fileData)) return false
        if (fileName != other.fileName) return false
        if (mimeType != other.mimeType) return false
        return true
    }

    override fun hashCode(): Int {
        var result = albumId
        result = 31 * result + fileData.contentHashCode()
        result = 31 * result + fileName.hashCode()
        result = 31 * result + mimeType.hashCode()
        return result
    }
}
