package com.example.memoriesapp.usecase

/**
 * Deep link types supported by the app
 */
sealed class DeepLink {
    data class Album(val albumId: Int) : DeepLink()

    companion object {
        /**
         * Parse a deep link URL string
         * Format: myapp://albums/{albumId}
         */
        fun parse(url: String): DeepLink? {
            // Simple parsing for myapp://albums/{albumId}
            val regex = Regex("^myapp://albums/(\\d+)$")
            val match = regex.find(url) ?: return null
            val albumId = match.groupValues[1].toIntOrNull() ?: return null
            return Album(albumId)
        }
    }
}
