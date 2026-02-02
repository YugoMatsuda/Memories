package com.example.memoriesapp.data.repository

import android.content.Context
import com.example.memoriesapp.core.LocalId
import com.example.memoriesapp.domain.ImageEntityType
import com.example.memoriesapp.repository.ImageStorageRepository
import java.io.File

/**
 * File-based implementation of ImageStorageRepository.
 * Saves images to the app's internal storage.
 */
class ImageStorageRepositoryImpl(
    private val context: Context
) : ImageStorageRepository {

    override fun save(data: ByteArray, entity: ImageEntityType, localId: LocalId): String {
        val file = getFile(entity, localId)
        file.parentFile?.mkdirs()
        file.writeBytes(data)
        return file.absolutePath
    }

    override fun get(entity: ImageEntityType, localId: LocalId): ByteArray {
        val file = getFile(entity, localId)
        return if (file.exists()) file.readBytes() else ByteArray(0)
    }

    override fun delete(entity: ImageEntityType, localId: LocalId) {
        val file = getFile(entity, localId)
        if (file.exists()) {
            file.delete()
        }
    }

    override fun getPath(entity: ImageEntityType, localId: LocalId): String {
        return getFile(entity, localId).absolutePath
    }

    private fun getFile(entity: ImageEntityType, localId: LocalId): File {
        val dir = File(context.filesDir, "images/${entity.path}")
        return File(dir, "$localId.jpg")
    }
}
