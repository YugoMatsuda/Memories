package com.example.memoriesapp.ui.uicomponents.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import coil.compose.SubcomposeAsyncImage
import coil.request.CachePolicy
import coil.request.ImageRequest

/**
 * CompositionLocal for base URL used to resolve relative image URLs.
 */
val LocalBaseUrl = staticCompositionLocalOf { "http://10.0.2.2:8000" }

/**
 * Resolve URL by prepending base URL if it's a relative path.
 * - Relative paths like "/uploads/image.jpg" -> "http://base/uploads/image.jpg"
 * - Absolute URLs are returned as-is
 * - Local file paths are returned as-is
 */
private fun resolveUrl(url: String, baseUrl: String): String {
    return when {
        url.startsWith("/") -> "$baseUrl$url"
        url.startsWith("http://") || url.startsWith("https://") -> url
        else -> url // Local file path
    }
}

/**
 * Async image component with caching, loading, and error states.
 */
@Composable
fun MemoryAsyncImage(
    url: String?,
    contentDescription: String?,
    modifier: Modifier = Modifier,
    contentScale: ContentScale = ContentScale.Crop
) {
    val baseUrl = LocalBaseUrl.current

    if (url.isNullOrBlank()) {
        PlaceholderContent(modifier = modifier)
        return
    }

    val resolvedUrl = resolveUrl(url, baseUrl)

    SubcomposeAsyncImage(
        model = ImageRequest.Builder(LocalContext.current)
            .data(resolvedUrl)
            .crossfade(true)
            .memoryCachePolicy(CachePolicy.ENABLED)
            .diskCachePolicy(CachePolicy.ENABLED)
            .build(),
        contentDescription = contentDescription,
        modifier = modifier,
        contentScale = contentScale,
        loading = {
            LoadingContent()
        },
        error = {
            PlaceholderContent()
        }
    )
}

@Composable
private fun LoadingContent() {
    Box(
        modifier = Modifier.background(MaterialTheme.colorScheme.surfaceVariant),
        contentAlignment = Alignment.Center
    ) {
        CircularProgressIndicator(
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
private fun PlaceholderContent(modifier: Modifier = Modifier) {
    Box(
        modifier = modifier.background(MaterialTheme.colorScheme.surfaceVariant),
        contentAlignment = Alignment.Center
    ) {
        Icon(
            painter = painterResource(android.R.drawable.ic_menu_gallery),
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}
