package com.example.memoriesapp.ui.navigation

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
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
import com.example.memoriesapp.domain.User
import com.example.memoriesapp.ui.uicomponents.screens.AlbumDetailScreen
import com.example.memoriesapp.ui.uicomponents.screens.AlbumFormScreen
import com.example.memoriesapp.ui.uicomponents.screens.AlbumListScreen
import com.example.memoriesapp.ui.uicomponents.screens.LoginScreen
import com.example.memoriesapp.ui.uicomponents.screens.MemoryFormScreen
import com.example.memoriesapp.ui.uicomponents.screens.SplashScreen
import com.example.memoriesapp.ui.uicomponents.screens.SyncQueuesScreen
import com.example.memoriesapp.ui.uicomponents.screens.UserProfileScreen
import com.example.memoriesapp.ui.uilogics.viewmodels.AlbumDetailViewModel
import com.example.memoriesapp.ui.uilogics.viewmodels.AlbumFormMode
import com.example.memoriesapp.ui.uilogics.viewmodels.AlbumFormViewModel
import com.example.memoriesapp.ui.uilogics.viewmodels.AlbumListViewModel
import com.example.memoriesapp.ui.uilogics.viewmodels.LoginViewModel
import com.example.memoriesapp.ui.uilogics.viewmodels.MemoryFormViewModel
import com.example.memoriesapp.ui.uilogics.viewmodels.SplashViewModel
import com.example.memoriesapp.ui.uilogics.viewmodels.SyncQueuesViewModel
import com.example.memoriesapp.ui.uilogics.viewmodels.UserProfileViewModel

/**
 * Root state for app navigation.
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
        is RootState.Launching -> Route.Login.route
        is RootState.Unauthenticated -> Route.Login.route
        is RootState.Authenticated -> Route.Splash.route
    }

    // Authenticated container (created when authenticated)
    val authenticatedContainer = remember(rootState) {
        (rootState as? RootState.Authenticated)?.let { auth ->
            appContainer.createAuthenticatedContainer(auth.token, auth.userId)
        }
    }

    // Selected album for detail view and memory form
    var selectedAlbum by remember { mutableStateOf<Album?>(null) }
    // Current user for profile
    var currentUser by remember { mutableStateOf<User?>(null) }

    NavHost(
        navController = navController,
        startDestination = startDestination
    ) {
        // Login Screen
        composable(Route.Login.route) {
            val viewModel = remember {
                LoginViewModel(loginUseCase = appContainer.loginUseCase)
            }
            LoginScreen(
                viewModel = viewModel,
                onLoginSuccess = { session ->
                    onLoginSuccess(session.token, session.userId)
                }
            )
        }

        // Splash Screen (authenticated)
        composable(Route.Splash.route) {
            val container = authenticatedContainer ?: return@composable
            val hasPreviousSession = (rootState as? RootState.Authenticated)?.hasPreviousSession ?: false
            val viewModel = remember(container) {
                SplashViewModel(splashUseCase = container.splashUseCase)
            }
            SplashScreen(
                viewModel = viewModel,
                onLaunchSuccess = { user ->
                    currentUser = user
                    if (hasPreviousSession) {
                        // Show ContinueAs screen
                        navController.navigate(Route.ContinueAs.route) {
                            popUpTo(Route.Splash.route) { inclusive = true }
                        }
                    } else {
                        // Direct to AlbumList for new login
                        navController.navigate(Route.AlbumList.route) {
                            popUpTo(Route.Splash.route) { inclusive = true }
                        }
                    }
                },
                onSessionExpired = onLogout
            )
        }

        // Continue As Screen (shows login with continue option)
        composable(Route.ContinueAs.route) {
            val user = currentUser ?: return@composable
            val continueAsItem = LoginViewModel.ContinueAsItem(
                userName = user.name,
                avatarUrl = user.avatarUrl
            )
            val viewModel = remember(continueAsItem) {
                LoginViewModel(
                    loginUseCase = appContainer.loginUseCase,
                    continueAsItem = continueAsItem
                )
            }
            LoginScreen(
                viewModel = viewModel,
                onLoginSuccess = { session ->
                    // New login, update root state
                    onLoginSuccess(session.token, session.userId)
                },
                onContinueAsUser = {
                    // Continue with existing session
                    navController.navigate(Route.AlbumList.route) {
                        popUpTo(Route.ContinueAs.route) { inclusive = true }
                    }
                }
            )
        }

        // Album List Screen
        composable(Route.AlbumList.route) {
            val container = authenticatedContainer ?: return@composable
            val viewModel = remember(container) {
                AlbumListViewModel(albumListUseCase = container.albumListUseCase)
            }
            AlbumListScreen(
                viewModel = viewModel,
                onNavigateToAlbumDetail = { album ->
                    selectedAlbum = album
                    navController.navigate(Route.AlbumDetail.createRoute(album.localId.toString()))
                },
                onNavigateToCreateAlbum = {
                    navController.navigate(Route.AlbumForm.createRoute())
                },
                onNavigateToEditAlbum = { album ->
                    navController.navigate(Route.AlbumForm.createRoute(album.localId.toString()))
                },
                onNavigateToUserProfile = {
                    navController.navigate(Route.UserProfile.route)
                },
                onNavigateToSyncQueues = {
                    navController.navigate(Route.SyncQueues.route)
                }
            )
        }

        // Album Detail Screen
        composable(Route.AlbumDetail.route) {
            val container = authenticatedContainer ?: return@composable
            val album = selectedAlbum ?: return@composable

            val viewModel = remember(container, album.localId) {
                AlbumDetailViewModel(
                    initialAlbum = album,
                    albumDetailUseCase = container.albumDetailUseCase
                )
            }

            // Update ViewModel's album when selectedAlbum changes
            LaunchedEffect(album) {
                viewModel.updateAlbum(album)
            }
            AlbumDetailScreen(
                viewModel = viewModel,
                onNavigateBack = { navController.popBackStack() },
                onNavigateToEditAlbum = { albumToEdit ->
                    navController.navigate(Route.AlbumForm.createRoute(albumToEdit.localId.toString()))
                },
                onNavigateToCreateMemory = { albumForMemory ->
                    navController.navigate(Route.MemoryForm.createRoute(albumForMemory.localId.toString()))
                }
            )
        }

        // User Profile Screen
        composable(Route.UserProfile.route) {
            val container = authenticatedContainer ?: return@composable
            val user = currentUser ?: return@composable
            val viewModel = remember(container, user) {
                UserProfileViewModel(
                    user = user,
                    userProfileUseCase = container.userProfileUseCase
                )
            }
            UserProfileScreen(
                viewModel = viewModel,
                onNavigateBack = { navController.popBackStack() },
                onLogout = onLogout,
                onProfileUpdated = { updatedUser ->
                    currentUser = updatedUser
                }
            )
        }

        // Album Form Screen (Create/Edit)
        composable(Route.AlbumForm.route) { backStackEntry ->
            val container = authenticatedContainer ?: return@composable
            val albumLocalId = backStackEntry.arguments?.getString("albumLocalId")
            val mode = if (albumLocalId != null && selectedAlbum?.localId?.toString() == albumLocalId) {
                AlbumFormMode.Edit(selectedAlbum!!)
            } else {
                AlbumFormMode.Create
            }
            val viewModel = remember(container, mode) {
                AlbumFormViewModel(
                    mode = mode,
                    albumFormUseCase = container.albumFormUseCase
                )
            }
            AlbumFormScreen(
                viewModel = viewModel,
                onDismiss = { updatedAlbum ->
                    if (updatedAlbum != null) {
                        selectedAlbum = updatedAlbum
                    }
                    navController.popBackStack()
                }
            )
        }

        // Memory Form Screen
        composable(Route.MemoryForm.route) {
            val container = authenticatedContainer ?: return@composable
            val album = selectedAlbum ?: return@composable
            val viewModel = remember(container, album) {
                MemoryFormViewModel(
                    album = album,
                    memoryFormUseCase = container.memoryFormUseCase
                )
            }
            MemoryFormScreen(
                viewModel = viewModel,
                onDismiss = { navController.popBackStack() }
            )
        }

        // Sync Queues Screen
        composable(Route.SyncQueues.route) {
            val container = authenticatedContainer ?: return@composable
            val viewModel = remember(container) {
                SyncQueuesViewModel(syncQueuesUseCase = container.syncQueuesUseCase)
            }
            SyncQueuesScreen(
                viewModel = viewModel,
                onNavigateBack = { navController.popBackStack() }
            )
        }
    }
}
