package com.example.memoriesapp.ui.uicomponents.screens

import com.example.memoriesapp.ui.uilogics.viewmodels.UserProfileViewModel

import android.graphics.Bitmap
import android.graphics.ImageDecoder
import android.os.Build
import android.provider.MediaStore
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import kotlinx.datetime.Instant
import kotlinx.datetime.LocalDate
import kotlinx.datetime.TimeZone
import kotlinx.datetime.atStartOfDayIn
import kotlinx.datetime.toLocalDateTime
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import com.example.memoriesapp.domain.User
import com.example.memoriesapp.ui.uicomponents.components.MemoryAsyncImage

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun UserProfileScreen(
    viewModel: UserProfileViewModel,
    onNavigateBack: () -> Unit,
    onLogout: () -> Unit,
    onProfileUpdated: (User) -> Unit
) {
    val context = LocalContext.current

    val imagePickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri ->
        uri?.let {
            val bitmap = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                ImageDecoder.decodeBitmap(ImageDecoder.createSource(context.contentResolver, it))
            } else {
                @Suppress("DEPRECATION")
                MediaStore.Images.Media.getBitmap(context.contentResolver, it)
            }
            viewModel.onImageSelected(bitmap)
        }
    }

    LaunchedEffect(Unit) {
        viewModel.navigationEvent.collect { event ->
            when (event) {
                is UserProfileViewModel.NavigationEvent.Logout -> onLogout()
            }
        }
    }

    // Alert dialogs
    viewModel.alertState?.let { state ->
        when (state) {
            is UserProfileViewModel.AlertState.LogoutConfirmation -> {
                AlertDialog(
                    onDismissRequest = { viewModel.dismissAlert() },
                    title = { Text("Logout") },
                    text = { Text("Are you sure you want to logout?") },
                    confirmButton = {
                        TextButton(onClick = { viewModel.confirmLogout() }) {
                            Text("Logout", color = MaterialTheme.colorScheme.error)
                        }
                    },
                    dismissButton = {
                        TextButton(onClick = { viewModel.dismissAlert() }) {
                            Text("Cancel")
                        }
                    }
                )
            }
            is UserProfileViewModel.AlertState.SaveSuccess -> {
                AlertDialog(
                    onDismissRequest = {
                        onProfileUpdated(state.updatedUser)
                        viewModel.dismissAlert()
                    },
                    title = { Text("Saved") },
                    text = { Text(state.message) },
                    confirmButton = {
                        TextButton(onClick = {
                            onProfileUpdated(state.updatedUser)
                            viewModel.dismissAlert()
                        }) {
                            Text("OK")
                        }
                    }
                )
            }
            is UserProfileViewModel.AlertState.SaveError -> {
                AlertDialog(
                    onDismissRequest = { viewModel.dismissAlert() },
                    title = { Text("Save Failed") },
                    text = { Text(state.message) },
                    confirmButton = {
                        TextButton(onClick = { viewModel.dismissAlert() }) {
                            Text("OK")
                        }
                    }
                )
            }
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Profile") },
                navigationIcon = {
                    androidx.compose.material3.IconButton(onClick = onNavigateBack) {
                        Icon(
                            painter = painterResource(android.R.drawable.ic_menu_revert),
                            contentDescription = "Back"
                        )
                    }
                },
                actions = {
                    if (viewModel.isSaving) {
                        CircularProgressIndicator(
                            modifier = Modifier
                                .size(24.dp)
                                .padding(end = 16.dp)
                        )
                    } else {
                        TextButton(
                            onClick = viewModel::save,
                            enabled = viewModel.isValid
                        ) {
                            Text("Save")
                        }
                    }
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .verticalScroll(rememberScrollState())
        ) {
            // Avatar Section
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 24.dp),
                contentAlignment = Alignment.Center
            ) {
                AvatarImage(
                    selectedImage = viewModel.selectedImage,
                    avatarUrl = viewModel.avatarUrl,
                    onClick = { imagePickerLauncher.launch("image/*") },
                    enabled = !viewModel.isSaving
                )
            }

            HorizontalDivider()

            // Name field
            OutlinedTextField(
                value = viewModel.name,
                onValueChange = viewModel::onNameChange,
                label = { Text("Name") },
                singleLine = true,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp)
            )

            // Username (read-only)
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Username",
                    style = MaterialTheme.typography.bodyLarge
                )
                Spacer(modifier = Modifier.weight(1f))
                Text(
                    text = viewModel.username,
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            HorizontalDivider()

            // Birthday
            OptionalDatePickerField(
                label = "Birthday",
                date = viewModel.birthday,
                onDateChange = viewModel::onBirthdayChange,
                enabled = !viewModel.isSaving
            )

            HorizontalDivider()

            Spacer(modifier = Modifier.height(32.dp))

            // Logout button
            Button(
                onClick = viewModel::showLogoutConfirmation,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = MaterialTheme.colorScheme.error
                )
            ) {
                Text("Logout")
            }
        }
    }
}

@Composable
private fun AvatarImage(
    selectedImage: Bitmap?,
    avatarUrl: String?,
    onClick: () -> Unit,
    enabled: Boolean
) {
    Box(
        modifier = Modifier
            .size(100.dp)
            .clip(CircleShape)
            .clickable(enabled = enabled, onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        when {
            selectedImage != null -> {
                androidx.compose.foundation.Image(
                    bitmap = selectedImage.asImageBitmap(),
                    contentDescription = "Selected avatar",
                    modifier = Modifier.fillMaxSize(),
                    contentScale = ContentScale.Crop
                )
            }
            avatarUrl != null -> {
                MemoryAsyncImage(
                    url = avatarUrl,
                    contentDescription = "Avatar",
                    modifier = Modifier.fillMaxSize()
                )
            }
            else -> {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(MaterialTheme.colorScheme.surfaceVariant),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        painter = painterResource(android.R.drawable.ic_menu_myplaces),
                        contentDescription = null,
                        modifier = Modifier.size(40.dp),
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun OptionalDatePickerField(
    label: String,
    date: LocalDate?,
    onDateChange: (LocalDate?) -> Unit,
    enabled: Boolean
) {
    var showDatePicker by remember { mutableStateOf(false) }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(enabled = enabled) { showDatePicker = true }
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyLarge
        )
        Spacer(modifier = Modifier.weight(1f))
        Text(
            text = date?.let { formatDate(it) } ?: "Not set",
            style = MaterialTheme.typography.bodyLarge,
            color = if (date != null) {
                MaterialTheme.colorScheme.onSurface
            } else {
                MaterialTheme.colorScheme.onSurfaceVariant
            }
        )
    }

    if (showDatePicker) {
        val datePickerState = rememberDatePickerState(
            initialSelectedDateMillis = date?.atStartOfDayIn(TimeZone.UTC)?.toEpochMilliseconds()
        )

        DatePickerDialog(
            onDismissRequest = { showDatePicker = false },
            confirmButton = {
                TextButton(
                    onClick = {
                        datePickerState.selectedDateMillis?.let { millis ->
                            val instant = Instant.fromEpochMilliseconds(millis)
                            val localDate = instant.toLocalDateTime(TimeZone.UTC).date
                            onDateChange(localDate)
                        }
                        showDatePicker = false
                    }
                ) {
                    Text("OK")
                }
            },
            dismissButton = {
                Row {
                    if (date != null) {
                        TextButton(
                            onClick = {
                                onDateChange(null)
                                showDatePicker = false
                            }
                        ) {
                            Text("Clear")
                        }
                    }
                    TextButton(onClick = { showDatePicker = false }) {
                        Text("Cancel")
                    }
                }
            }
        ) {
            DatePicker(state = datePickerState)
        }
    }
}

private fun formatDate(date: LocalDate): String {
    val monthName = date.month.name.lowercase().replaceFirstChar { it.uppercase() }
    return "$monthName ${date.dayOfMonth}, ${date.year}"
}
