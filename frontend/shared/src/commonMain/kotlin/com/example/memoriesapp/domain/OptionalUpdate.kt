package com.example.memoriesapp.domain

/**
 * Represents an optional update operation for a field.
 * Used in `copy` methods to distinguish between:
 * - Not changing the field
 * - Explicitly setting the field to null
 * - Setting a new value
 */
sealed class OptionalUpdate<out T> {
    /** Keep the current value (don't update) */
    data object NoChange : OptionalUpdate<Nothing>()

    /** Set to null */
    data object SetNull : OptionalUpdate<Nothing>()

    /** Set to a new value */
    data class Set<T>(val value: T) : OptionalUpdate<T>()

    companion object {
        /**
         * Creates an OptionalUpdate from a nullable value
         * - null becomes SetNull
         * - value becomes Set(value)
         */
        fun <T> from(value: T?): OptionalUpdate<T> =
            if (value != null) Set(value) else SetNull
    }

    /**
     * Resolves the update against the current value
     */
    fun resolve(current: @UnsafeVariance T?): T? = when (this) {
        is NoChange -> current
        is SetNull -> null
        is Set -> value
    }
}
