package com.example.memoriesapp

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.asSharedFlow

class MainActivity : ComponentActivity() {
    private val _deepLinkFlow = MutableSharedFlow<String>(extraBufferCapacity = 1)
    val deepLinkFlow = _deepLinkFlow.asSharedFlow()

    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)

        // Cold start: get deep link from launch intent
        val initialDeepLink = intent?.data?.toString()

        setContent {
            App(
                initialDeepLinkUrl = initialDeepLink,
                deepLinkFlow = deepLinkFlow
            )
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Warm start: emit deep link to flow
        intent.data?.toString()?.let { url ->
            _deepLinkFlow.tryEmit(url)
        }
    }
}
