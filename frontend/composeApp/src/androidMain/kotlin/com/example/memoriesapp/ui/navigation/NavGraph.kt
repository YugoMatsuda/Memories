package com.example.memoriesapp.ui.navigation

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import com.example.memoriesapp.di.AppContainer
import com.example.memoriesapp.di.AuthenticatedContainer
import com.example.memoriesapp.domain.Album
import com.example.memoriesapp.ui.screens.albumdetail.AlbumDetailScreen
import com.example.memoriesapp.ui.screens.albumdetail.AlbumDetailViewModel
import com.example.memoriesapp.ui.screens.albumlist.AlbumListScreen
import com.example.memoriesapp.ui.screens.albumlist.AlbumListViewModel
import com.example.memoriesapp.ui.screens.login.LoginScreen
import com.example.memoriesapp.ui.screens.login.LoginViewModel
import com.example.memoriesapp.ui.screens.splash.SplashScreen
import com.example.memoriesapp.ui.screens.splash.SplashViewModel

/**
 * Root state for app navigation.
 * Mirrors iOS RootViewState.
 */
sealed class RootState {
    data object Launching : RootState()
    data object Unauthenticated : RootState()
    data class Authenticated(
        val token: String,
        val userId: Int,
        val hasPreviousSession: Boolean
    ) : RootState()
}

@Composable
fun AppNavGraph(
    navController: NavHostController,
    appContainer: AppContainer,
    rootState: RootState,
    onLoginSuccess: (token: String, userId: Int) -> Unit,
    onLogout: () -> Unit
) {
    val startDestination = when (rootState) {
        is RootState.Launching -> Route.Login.route // Will be updated after init
        is RootState.Unauthenticated -> Route.Login.route
        is RootState.Authenticated -> Route.Splash.route
    }

    // Authenticated container (created when authenticated)
    val authenticatedContainer = remember(rootState) {
        (rootState as? RootState.Authenticated)?.let { auth ->
            appContainer.createAuthenticatedContainer(auth.token, auth.userId)
        }
    }

    // Selected album for detail view
    var selectedAlbum by remember { mutableStateOf<Album?>(null) }

    NavHost(
        navController = navController,
        startDestination = startDestination
    ) {
        // Login Screen
        composable(Route.Login.route) {
            val viewModel = remember {
                LoginViewModel(
                    loginUseCase = appContainer.loginUseCase,
                    onSuccess = { session ->
                        onLoginSuccess(session.token, session.userId)
                    }
                )
            }
            LoginScreen(viewModel = viewModel)
        }

        // Splash Screen (authenticated)
        composable(Route.Splash.route) {
            val container = authenticatedContainer ?: return@composable
            val viewModel = remember(container) {
                SplashViewModel(
                    splashUseCase = container.splashUseCase,
                    onSuccess = { _ ->
                        navController.navigate(Route.AlbumList.route) {
                            popUpTo(Route.Splash.route) { inclusive = true }
                        }
                    },
                    onSessionExpired = onLogout
                )
            }
            SplashScreen(viewModel = viewModel)
        }

        // Album List Screen
        composable(Route.AlbumList.route) {
            val container = authenticatedContainer ?: return@composable
            val viewModel = remember(container) {
                AlbumListViewModel(
                    albumListUseCase = container.albumListUseCase,
                    onAlbumTap = { album ->
                        selectedAlbum = album
                        navController.navigate(Route.AlbumDetail.createRoute(album.localId.toString()))
                    },
                    onUserProfileTap = {
                        navController.navigate(Route.UserProfile.route)
                    },
                    onCreateAlbumTap = {
                        navController.navigate(Route.AlbumForm.createRoute())
                    },
                    onSyncQueuesTap = {
                        navController.navigate(Route.SyncQueues.route)
                    }
                )
            }
            AlbumListScreen(viewModel = viewModel)
        }

        // Album Detail Screen
        composable(Route.AlbumDetail.route) {
            val container = authenticatedContainer ?: return@composable
            val album = selectedAlbum ?: return@composable

            val viewModel = remember(container, album) {
                AlbumDetailViewModel(
                    initialAlbum = album,
                    albumDetailUseCase = container.albumDetailUseCase,
                    onEditAlbumTap = { albumToEdit ->
                        navController.navigate(Route.AlbumForm.createRoute(albumToEdit.localId.toString()))
                    },
                    onCreateMemoryTap = { albumForMemory ->
                        navController.navigate(Route.MemoryForm.createRoute(albumForMemory.localId.toString()))
                    }
                )
            }
            AlbumDetailScreen(
                viewModel = viewModel,
                onNavigateBack = { navController.popBackStack() }
            )
        }

        // TODO: Add other screens (AlbumForm, MemoryForm, UserProfile, SyncQueues)
        composable(Route.UserProfile.route) {
            // Placeholder
            androidx.compose.material3.Text("User Profile - Coming Soon")
        }

        composable(Route.AlbumForm.route) {
            // Placeholder
            androidx.compose.material3.Text("Album Form - Coming Soon")
        }

        composable(Route.MemoryForm.route) {
            // Placeholder
            androidx.compose.material3.Text("Memory Form - Coming Soon")
        }

        composable(Route.SyncQueues.route) {
            // Placeholder
            androidx.compose.material3.Text("Sync Queues - Coming Soon")
        }
    }
}
