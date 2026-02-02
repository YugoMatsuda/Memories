package com.example.memoriesapp.domain

import com.example.memoriesapp.core.LocalId

enum class MimeType(val value: String) {
    JPEG("image/jpeg");

    val fileExtension: String
        get() = when (this) {
            JPEG -> "jpg"
        }

    fun fileName(id: LocalId): String = "${id}.${fileExtension}"
}
