package com.example.memoriesapp.ui.uicomponents.screens

import com.example.memoriesapp.ui.uilogics.viewmodels.AlbumDetailViewModel

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectVerticalDragGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.itemsIndexed
import androidx.compose.foundation.lazy.grid.rememberLazyGridState
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.example.memoriesapp.core.SyncStatus
import com.example.memoriesapp.domain.Album
import com.example.memoriesapp.ui.uicomponents.components.MemoryAsyncImage

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AlbumDetailScreen(
    viewModel: AlbumDetailViewModel,
    onNavigateBack: () -> Unit,
    onNavigateToEditAlbum: (Album) -> Unit,
    onNavigateToCreateMemory: (Album) -> Unit
) {
    // Observe navigation events
    LaunchedEffect(Unit) {
        viewModel.navigationEvent.collect { event ->
            when (event) {
                is AlbumDetailViewModel.NavigationEvent.EditAlbum -> {
                    onNavigateToEditAlbum(event.album)
                }
                is AlbumDetailViewModel.NavigationEvent.CreateMemory -> {
                    onNavigateToCreateMemory(event.album)
                }
                is AlbumDetailViewModel.NavigationEvent.Back -> {
                    onNavigateBack()
                }
            }
        }
    }

    LaunchedEffect(Unit) {
        viewModel.onAppear()
    }

    val album = viewModel.album

    Box(modifier = Modifier.fillMaxSize()) {
        Scaffold(
            topBar = {
                TopAppBar(
                    title = {
                        Text(
                            text = album?.title ?: "Loading...",
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    },
                    navigationIcon = {
                        IconButton(onClick = onNavigateBack) {
                            Icon(
                                painter = painterResource(android.R.drawable.ic_menu_revert),
                                contentDescription = "Back"
                            )
                        }
                    },
                    actions = {
                        if (album != null) {
                            IconButton(onClick = viewModel::showEditAlbumForm) {
                                Icon(
                                    painter = painterResource(android.R.drawable.ic_menu_edit),
                                    contentDescription = "Edit Album"
                                )
                            }
                        }
                    }
                )
            },
            floatingActionButton = {
                if (album != null) {
                    FloatingActionButton(onClick = viewModel::showCreateMemoryForm) {
                        Icon(
                            painter = painterResource(android.R.drawable.ic_input_add),
                            contentDescription = "Add Memory"
                        )
                    }
                }
            }
        ) { paddingValues ->
            when (val result = viewModel.displayResult) {
                is AlbumDetailViewModel.DisplayResult.Loading -> {
                    LoadingContent(modifier = Modifier.padding(paddingValues))
                }
                is AlbumDetailViewModel.DisplayResult.Success -> {
                    MemoryGridContent(
                        data = result.data,
                        isLoadingMore = viewModel.isLoadingMore,
                        onLoadMore = viewModel::onLoadMore,
                        onMemoryTap = viewModel::showMemoryViewer,
                        modifier = Modifier.padding(paddingValues)
                    )
                }
                is AlbumDetailViewModel.DisplayResult.Failure -> {
                    ErrorContent(
                        error = result.error,
                        modifier = Modifier.padding(paddingValues)
                    )
                }
            }
        }

        // Memory Viewer overlay
        val viewerMemoryId = viewModel.viewerMemoryId
        val displayResult = viewModel.displayResult
        AnimatedVisibility(
            visible = viewerMemoryId != null && displayResult is AlbumDetailViewModel.DisplayResult.Success,
            enter = fadeIn(),
            exit = fadeOut()
        ) {
            if (viewerMemoryId != null && displayResult is AlbumDetailViewModel.DisplayResult.Success) {
                MemoryViewer(
                    items = displayResult.data.items,
                    initialMemoryId = viewerMemoryId,
                    onDismiss = viewModel::closeMemoryViewer
                )
            }
        }
    }
}

@Composable
private fun LoadingContent(modifier: Modifier = Modifier) {
    Box(
        modifier = modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        CircularProgressIndicator()
    }
}

@Composable
private fun MemoryGridContent(
    data: AlbumDetailViewModel.ListData,
    isLoadingMore: Boolean,
    onLoadMore: () -> Unit,
    onMemoryTap: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    val gridState = rememberLazyGridState()

    if (data.items.isEmpty()) {
        EmptyContent(modifier = modifier)
    } else {
        LazyVerticalGrid(
            columns = GridCells.Fixed(2),
            state = gridState,
            contentPadding = PaddingValues(horizontal = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
            modifier = modifier.fillMaxSize()
        ) {
            itemsIndexed(data.items, key = { _, item -> item.localId }) { index, item ->
                // Trigger load more when approaching the end (4 items before for 2-column grid)
                if (index >= data.items.size - 4 && data.hasMore && !isLoadingMore) {
                    LaunchedEffect(data.items.size) {
                        onLoadMore()
                    }
                }

                MemoryCard(
                    item = item,
                    onTap = { onMemoryTap(item.localId) }
                )
            }

            // Loading more indicator (spans full width)
            if (isLoadingMore) {
                item(span = { GridItemSpan(2) }) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator(modifier = Modifier.size(24.dp))
                    }
                }
            }
        }
    }
}

@Composable
private fun MemoryCard(
    item: AlbumDetailViewModel.MemoryItemUIModel,
    onTap: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .aspectRatio(2f / 3f)
            .clip(RoundedCornerShape(8.dp))
            .clickable(onClick = onTap)
    ) {
        MemoryAsyncImage(
            url = item.displayImage,
            contentDescription = item.title,
            modifier = Modifier.fillMaxSize()
        )

        // Sync status indicator
        if (item.syncStatus != SyncStatus.SYNCED) {
            Box(
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(4.dp)
            ) {
                Icon(
                    painter = painterResource(android.R.drawable.stat_notify_sync),
                    contentDescription = "Pending sync",
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(16.dp)
                )
            }
        }
    }
}

@Composable
private fun EmptyContent(modifier: Modifier = Modifier) {
    Box(
        modifier = modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Icon(
                painter = painterResource(android.R.drawable.ic_menu_gallery),
                contentDescription = null,
                modifier = Modifier.size(48.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Text(
                text = "No memories yet",
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Text(
                text = "Tap + to add your first memory",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun ErrorContent(
    error: AlbumDetailViewModel.ErrorUIModel,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                text = error.message,
                textAlign = TextAlign.Center,
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            TextButton(onClick = error.onRetry) {
                Text("Retry")
            }
        }
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun MemoryViewer(
    items: List<AlbumDetailViewModel.MemoryItemUIModel>,
    initialMemoryId: String,
    onDismiss: () -> Unit
) {
    val initialPage = items.indexOfFirst { it.localId == initialMemoryId }.coerceAtLeast(0)
    val pagerState = rememberPagerState(initialPage = initialPage) { items.size }

    // Track vertical drag for swipe-to-dismiss
    var dragOffset by remember { mutableFloatStateOf(0f) }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
            .pointerInput(Unit) {
                detectVerticalDragGestures(
                    onDragEnd = {
                        if (dragOffset > 100f) {
                            onDismiss()
                        }
                        dragOffset = 0f
                    },
                    onVerticalDrag = { _, dragAmount ->
                        if (dragAmount > 0) {
                            dragOffset += dragAmount
                        }
                    }
                )
            }
    ) {
        // Horizontal pager for images
        HorizontalPager(
            state = pagerState,
            modifier = Modifier.fillMaxSize()
        ) { page ->
            val item = items[page]
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                MemoryAsyncImage(
                    url = item.displayImage,
                    contentDescription = item.title,
                    modifier = Modifier.fillMaxSize(),
                    contentScale = ContentScale.Fit
                )
            }
        }

        // Close button (top left)
        IconButton(
            onClick = onDismiss,
            modifier = Modifier
                .align(Alignment.TopStart)
                .padding(start = 8.dp, top = 40.dp)
                .size(56.dp)
        ) {
            Box(
                modifier = Modifier
                    .size(44.dp)
                    .background(
                        color = Color.Black.copy(alpha = 0.4f),
                        shape = CircleShape
                    ),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    painter = painterResource(android.R.drawable.ic_menu_close_clear_cancel),
                    contentDescription = "Close",
                    tint = Color.White,
                    modifier = Modifier.size(24.dp)
                )
            }
        }

        // Bottom overlay with page indicator and title
        Column(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
                .background(
                    Brush.verticalGradient(
                        colors = listOf(Color.Transparent, Color.Black.copy(alpha = 0.5f))
                    )
                )
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Page indicator (only if more than 1 item)
            if (items.size > 1) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                    modifier = Modifier.padding(bottom = 12.dp)
                ) {
                    repeat(items.size) { index ->
                        Box(
                            modifier = Modifier
                                .size(8.dp)
                                .background(
                                    color = if (index == pagerState.currentPage) Color.White else Color.White.copy(alpha = 0.4f),
                                    shape = CircleShape
                                )
                        )
                    }
                }
            }

            // Title and date
            val currentItem = items.getOrNull(pagerState.currentPage)
            currentItem?.let { item ->
                Text(
                    text = item.title,
                    style = MaterialTheme.typography.titleMedium,
                    color = Color.White
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = formatDate(item.createdAt),
                    style = MaterialTheme.typography.bodySmall,
                    color = Color.White.copy(alpha = 0.7f)
                )
            }
        }
    }
}

private fun formatDate(timestamp: com.example.memoriesapp.core.Timestamp): String {
    val localDate = timestamp.toLocalDate()
    return "${localDate.month.name.lowercase().replaceFirstChar { it.uppercase() }} ${localDate.dayOfMonth}, ${localDate.year}"
}
