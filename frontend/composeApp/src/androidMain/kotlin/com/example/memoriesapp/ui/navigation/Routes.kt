package com.example.memoriesapp.ui.navigation

/**
 * Navigation routes for the app.
 */
sealed class Route(val route: String) {
    data object Login : Route("login")
    data object Splash : Route("splash")
    data object AlbumList : Route("albums")
    data object AlbumDetail : Route("albums/{albumLocalId}") {
        fun createRoute(albumLocalId: String) = "albums/$albumLocalId"
    }
    data object AlbumForm : Route("albums/form?albumLocalId={albumLocalId}") {
        fun createRoute(albumLocalId: String? = null) =
            if (albumLocalId != null) "albums/form?albumLocalId=$albumLocalId" else "albums/form"
    }
    data object MemoryForm : Route("albums/{albumLocalId}/memories/form") {
        fun createRoute(albumLocalId: String) = "albums/$albumLocalId/memories/form"
    }
    data object UserProfile : Route("profile")
    data object SyncQueues : Route("sync-queues")
}
