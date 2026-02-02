package com.example.memoriesapp.api.request

import com.example.memoriesapp.api.client.*

/**
 * Get paginated memories for an album
 * GET /albums/{albumId}/memories?page=X&page_size=Y
 */
data class GetMemoriesRequest(
    val albumId: Int,
    val page: Int = 1,
    val pageSize: Int = 20
) : ApiRequest {
    override val path: String = "/albums/$albumId/memories"
    override val method: HttpMethod = HttpMethod.GET
    override val queryParams: Map<String, String> = mapOf(
        "page" to page.toString(),
        "page_size" to pageSize.toString()
    )
}

/**
 * Upload new memory
 * POST /upload (multipart)
 */
data class MemoryUploadRequest(
    val albumId: Int,
    val title: String,
    val imageRemoteUrl: String? = null,
    val fileData: ByteArray? = null,
    val fileName: String? = null,
    val mimeType: String? = null
) : MultipartApiRequest {
    override val path: String = "/upload"
    override val method: HttpMethod = HttpMethod.POST

    override val formFields: List<MultipartFormField> = buildList {
        add(MultipartFormField("album_id", albumId.toString()))
        add(MultipartFormField("title", title))
        imageRemoteUrl?.let { add(MultipartFormField("image_remote_url", it)) }
    }

    override val fileFields: List<MultipartFileField> = buildList {
        if (fileData != null && fileName != null && mimeType != null) {
            add(MultipartFileField(
                name = "file",
                fileName = fileName,
                contentType = mimeType,
                data = fileData
            ))
        }
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other == null || this::class != other::class) return false
        other as MemoryUploadRequest
        if (albumId != other.albumId) return false
        if (title != other.title) return false
        if (imageRemoteUrl != other.imageRemoteUrl) return false
        if (fileData != null) {
            if (other.fileData == null) return false
            if (!fileData.contentEquals(other.fileData)) return false
        } else if (other.fileData != null) return false
        if (fileName != other.fileName) return false
        if (mimeType != other.mimeType) return false
        return true
    }

    override fun hashCode(): Int {
        var result = albumId
        result = 31 * result + title.hashCode()
        result = 31 * result + (imageRemoteUrl?.hashCode() ?: 0)
        result = 31 * result + (fileData?.contentHashCode() ?: 0)
        result = 31 * result + (fileName?.hashCode() ?: 0)
        result = 31 * result + (mimeType?.hashCode() ?: 0)
        return result
    }
}
