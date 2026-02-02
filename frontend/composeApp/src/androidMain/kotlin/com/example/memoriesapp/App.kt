package com.example.memoriesapp

import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext
import androidx.navigation.compose.rememberNavController
import com.example.memoriesapp.di.AppContainer
import com.example.memoriesapp.ui.uicomponents.components.LocalBaseUrl
import com.example.memoriesapp.ui.navigation.AppNavGraph
import com.example.memoriesapp.ui.navigation.Route
import com.example.memoriesapp.ui.navigation.RootState
import com.example.memoriesapp.ui.theme.MemoriesAppTheme
import com.example.memoriesapp.usecase.CheckPreviousSessionResult

/**
 * Main App composable.
 * Manages root state and navigation.
 */
@Composable
fun App() {
    val context = LocalContext.current
    val appContainer = remember { AppContainer(context.applicationContext) }
    val navController = rememberNavController()
    var rootState by remember { mutableStateOf<RootState>(RootState.Launching) }

    // Initialize: Check for previous session
    LaunchedEffect(Unit) {
        val result = appContainer.rootUseCase.checkPreviousSession()
        rootState = when (result) {
            is CheckPreviousSessionResult.LoggedIn -> {
                RootState.Authenticated(
                    token = result.session.token,
                    userId = result.session.userId,
                    hasPreviousSession = true
                )
            }
            is CheckPreviousSessionResult.NotLoggedIn -> {
                RootState.Unauthenticated
            }
        }
    }

    // Handle root state changes for navigation
    LaunchedEffect(rootState) {
        when (rootState) {
            is RootState.Launching -> {
                // Wait for initialization
            }
            is RootState.Unauthenticated -> {
                navController.navigate(Route.Login.route) {
                    popUpTo(0) { inclusive = true }
                }
            }
            is RootState.Authenticated -> {
                navController.navigate(Route.Splash.route) {
                    popUpTo(0) { inclusive = true }
                }
            }
        }
    }

    CompositionLocalProvider(LocalBaseUrl provides appContainer.baseUrl) {
        MemoriesAppTheme {
            AppNavGraph(
                navController = navController,
                appContainer = appContainer,
                rootState = rootState,
                onLoginSuccess = { token, userId ->
                    rootState = RootState.Authenticated(
                        token = token,
                        userId = userId,
                        hasPreviousSession = false
                    )
                },
                onLogout = {
                    rootState = RootState.Unauthenticated
                }
            )
        }
    }
}
