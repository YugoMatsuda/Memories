package com.example.memoriesapp

import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
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
import com.example.memoriesapp.usecase.DeepLink
import com.example.memoriesapp.usecase.HandleDeepLinkResult
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.emptyFlow

/**
 * Alert item for deep link errors.
 */
data class AlertItem(
    val title: String,
    val message: String
)

/**
 * Main App composable.
 * Manages root state and navigation.
 */
@Composable
fun App(
    initialDeepLinkUrl: String? = null,
    deepLinkFlow: Flow<String> = emptyFlow()
) {
    val context = LocalContext.current
    val appContainer = remember { AppContainer(context.applicationContext) }
    val navController = rememberNavController()
    var rootState by remember { mutableStateOf<RootState>(RootState.Launching) }

    // Deep link state
    var pendingDeepLink by remember { mutableStateOf<DeepLink?>(null) }
    var deepLinkToProcess by remember { mutableStateOf<DeepLink?>(null) }
    var alertItem by remember { mutableStateOf<AlertItem?>(null) }

    // Process deep link URL
    fun handleDeepLink(url: String) {
        val result = appContainer.rootUseCase.handleDeepLink(url)
        when (result) {
            is HandleDeepLinkResult.Authenticated -> {
                if (rootState is RootState.Authenticated) {
                    // Warm start: process immediately
                    deepLinkToProcess = result.deepLink
                } else {
                    // Cold start: save for later
                    pendingDeepLink = result.deepLink
                }
            }
            is HandleDeepLinkResult.NotAuthenticated -> {
                pendingDeepLink = result.deepLink
                alertItem = AlertItem(
                    title = "Login Required",
                    message = "Please log in to view this content."
                )
            }
            is HandleDeepLinkResult.InvalidURL -> {
                alertItem = AlertItem(
                    title = "Invalid Link",
                    message = "This link cannot be opened."
                )
            }
        }
    }

    // Cold start: handle initial deep link
    LaunchedEffect(initialDeepLinkUrl) {
        initialDeepLinkUrl?.let { url ->
            handleDeepLink(url)
        }
    }

    // Warm start: observe deep link flow
    LaunchedEffect(deepLinkFlow) {
        deepLinkFlow.collect { url ->
            handleDeepLink(url)
        }
    }

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

    // Alert dialog
    alertItem?.let { item ->
        AlertDialog(
            onDismissRequest = { alertItem = null },
            title = { Text(item.title) },
            text = { Text(item.message) },
            confirmButton = {
                TextButton(onClick = { alertItem = null }) {
                    Text("OK")
                }
            }
        )
    }

    CompositionLocalProvider(LocalBaseUrl provides appContainer.baseUrl) {
        MemoriesAppTheme {
            AppNavGraph(
                navController = navController,
                appContainer = appContainer,
                rootState = rootState,
                pendingDeepLink = pendingDeepLink,
                deepLinkToProcess = deepLinkToProcess,
                onDeepLinkConsumed = {
                    pendingDeepLink = null
                    deepLinkToProcess = null
                },
                onLoginSuccess = { token, userId ->
                    rootState = RootState.Authenticated(
                        token = token,
                        userId = userId,
                        hasPreviousSession = false
                    )
                },
                onLogout = {
                    rootState = RootState.Unauthenticated
                    pendingDeepLink = null
                    deepLinkToProcess = null
                }
            )
        }
    }
}
