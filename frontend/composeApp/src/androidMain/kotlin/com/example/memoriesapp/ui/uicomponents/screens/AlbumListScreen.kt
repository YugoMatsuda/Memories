package com.example.memoriesapp.ui.uicomponents.screens

import com.example.memoriesapp.ui.uilogics.viewmodels.AlbumListViewModel

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.example.memoriesapp.domain.Album
import com.example.memoriesapp.ui.uicomponents.components.MemoryAsyncImage

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AlbumListScreen(
    viewModel: AlbumListViewModel,
    onNavigateToAlbumDetail: (Album) -> Unit,
    onNavigateToCreateAlbum: () -> Unit,
    onNavigateToEditAlbum: (Album) -> Unit,
    onNavigateToUserProfile: () -> Unit,
    onNavigateToSyncQueues: () -> Unit
) {
    // Observe navigation events
    LaunchedEffect(Unit) {
        viewModel.navigationEvent.collect { event ->
            when (event) {
                is AlbumListViewModel.NavigationEvent.AlbumDetail -> {
                    onNavigateToAlbumDetail(event.album)
                }
                is AlbumListViewModel.NavigationEvent.CreateAlbum -> {
                    onNavigateToCreateAlbum()
                }
                is AlbumListViewModel.NavigationEvent.EditAlbum -> {
                    onNavigateToEditAlbum(event.album)
                }
                is AlbumListViewModel.NavigationEvent.UserProfile -> {
                    onNavigateToUserProfile()
                }
                is AlbumListViewModel.NavigationEvent.SyncQueues -> {
                    onNavigateToSyncQueues()
                }
            }
        }
    }

    LaunchedEffect(Unit) {
        viewModel.onAppear()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Memories") },
                actions = {
                    // User profile
                    IconButton(onClick = viewModel::showUserProfile) {
                        MemoryAsyncImage(
                            url = viewModel.userAvatarUrl,
                            contentDescription = "Profile",
                            modifier = Modifier
                                .size(32.dp)
                                .clip(CircleShape)
                        )
                    }
                }
            )
        },
        floatingActionButton = {
            FloatingActionButton(
                onClick = viewModel::showCreateAlbumForm,
                containerColor = MaterialTheme.colorScheme.primary
            ) {
                Icon(
                    painter = painterResource(android.R.drawable.ic_input_add),
                    contentDescription = "Create Album",
                    tint = MaterialTheme.colorScheme.onPrimary
                )
            }
        }
    ) { paddingValues ->
        when (val result = viewModel.displayResult) {
            is AlbumListViewModel.DisplayResult.Loading -> {
                LoadingContent(modifier = Modifier.padding(paddingValues))
            }
            is AlbumListViewModel.DisplayResult.Success -> {
                AlbumListContent(
                    data = result.data,
                    isLoadingMore = viewModel.isLoadingMore,
                    isRefreshing = false,
                    onRefresh = viewModel::onRefresh,
                    onLoadMore = viewModel::onLoadMore,
                    onAlbumTap = viewModel::onAlbumTap,
                    modifier = Modifier.padding(paddingValues)
                )
            }
            is AlbumListViewModel.DisplayResult.Failure -> {
                ErrorContent(
                    error = result.error,
                    modifier = Modifier.padding(paddingValues)
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

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun AlbumListContent(
    data: AlbumListViewModel.ListData,
    isLoadingMore: Boolean,
    isRefreshing: Boolean,
    onRefresh: () -> Unit,
    onLoadMore: () -> Unit,
    onAlbumTap: (Album) -> Unit,
    modifier: Modifier = Modifier
) {
    val listState = rememberLazyListState()

    PullToRefreshBox(
        isRefreshing = isRefreshing,
        onRefresh = onRefresh,
        modifier = modifier.fillMaxSize()
    ) {
        if (data.items.isEmpty()) {
            EmptyContent()
        } else {
            LazyColumn(
                state = listState,
                modifier = Modifier.fillMaxSize()
            ) {
                itemsIndexed(data.items, key = { _, item -> item.localId }) { index, item ->
                    val album = data.albums.find { it.localId.toString() == item.localId }

                    // Trigger load more when approaching the end (3 items before)
                    if (index >= data.items.size - 3 && data.hasMore && !isLoadingMore) {
                        LaunchedEffect(data.items.size) {
                            onLoadMore()
                        }
                    }

                    AlbumRow(
                        item = item,
                        onTap = { album?.let { onAlbumTap(it) } }
                    )
                    HorizontalDivider()
                }

                // Loading more indicator
                if (isLoadingMore) {
                    item {
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
}

@Composable
private fun AlbumRow(
    item: AlbumListViewModel.AlbumItemUIModel,
    onTap: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onTap)
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Thumbnail (50x50)
        MemoryAsyncImage(
            url = item.coverImageUrl,
            contentDescription = item.title,
            modifier = Modifier
                .size(50.dp)
                .clip(RoundedCornerShape(6.dp))
        )

        Spacer(modifier = Modifier.width(12.dp))

        // Title
        Text(
            text = item.title,
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurface
        )
    }
}

@Composable
private fun EmptyContent() {
    Box(
        modifier = Modifier.fillMaxSize(),
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
                text = "No albums yet",
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Text(
                text = "Tap + to create your first album",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun ErrorContent(
    error: AlbumListViewModel.ErrorUIModel,
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
