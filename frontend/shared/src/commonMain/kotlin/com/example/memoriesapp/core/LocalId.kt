package com.example.memoriesapp.core

import kotlin.uuid.ExperimentalUuidApi
import kotlin.uuid.Uuid

/**
 * A wrapper around UUID for local entity identification.
 */
@OptIn(ExperimentalUuidApi::class)
data class LocalId(val value: Uuid) {

    override fun toString(): String = value.toString()

    companion object {
        fun generate(): LocalId = LocalId(Uuid.random())

        fun fromString(value: String): LocalId = LocalId(Uuid.parse(value))
    }
}
