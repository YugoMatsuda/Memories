package com.example.memoriesapp.ui.uicomponents.screens

import com.example.memoriesapp.ui.uilogics.viewmodels.SplashViewModel

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.example.memoriesapp.domain.User

@Composable
fun SplashScreen(
    viewModel: SplashViewModel,
    onLaunchSuccess: (User) -> Unit,
    onSessionExpired: () -> Unit
) {
    // Observe navigation events
    LaunchedEffect(Unit) {
        viewModel.navigationEvent.collect { event ->
            when (event) {
                is SplashViewModel.NavigationEvent.LaunchSuccess -> {
                    onLaunchSuccess(event.user)
                }
                is SplashViewModel.NavigationEvent.SessionExpired -> {
                    onSessionExpired()
                }
            }
        }
    }

    LaunchedEffect(Unit) {
        if (viewModel.state is SplashViewModel.State.Initial) {
            viewModel.launchApp()
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        when (val state = viewModel.state) {
            is SplashViewModel.State.Initial,
            is SplashViewModel.State.Loading -> {
                CircularProgressIndicator()
                Spacer(modifier = Modifier.height(16.dp))
                Text(
                    text = if (state is SplashViewModel.State.Loading) state.message else "Loading...",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            is SplashViewModel.State.Error -> {
                Text(
                    text = state.item.message,
                    style = MaterialTheme.typography.bodyLarge,
                    textAlign = TextAlign.Center,
                    color = MaterialTheme.colorScheme.error
                )
                Spacer(modifier = Modifier.height(24.dp))
                Button(onClick = state.item.action) {
                    Text(state.item.buttonTitle)
                }
            }
        }
    }
}
