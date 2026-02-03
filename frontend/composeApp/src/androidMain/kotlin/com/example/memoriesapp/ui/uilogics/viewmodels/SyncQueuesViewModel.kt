package com.example.memoriesapp.ui.uilogics.viewmodels

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.memoriesapp.domain.SyncOperationStatus
import com.example.memoriesapp.usecase.SyncQueuesUseCase
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class SyncQueuesViewModel(
    private val syncQueuesUseCase: SyncQueuesUseCase
) : ViewModel() {

    var items by mutableStateOf<List<SyncOperationUIModel>>(emptyList())
        private set

    init {
        // Observe state changes and refresh list
        syncQueuesUseCase.observeState()
            .onEach { loadItems() }
            .launchIn(viewModelScope)
    }

    fun onAppear() {
        viewModelScope.launch {
            loadItems()
        }
    }

    private suspend fun loadItems() {
        val queueItems = syncQueuesUseCase.getAll()
        items = queueItems.map { item ->
            val op = item.operation
            SyncOperationUIModel(
                id = op.id.toString(),
                entityType = op.entityType.name,
                operationType = op.operationType.name,
                entityTitle = item.entityTitle,
                localId = op.localId.toString().take(8),
                serverId = item.entityServerId?.toString(),
                createdAt = formatDate(op.createdAt.epochMillis),
                status = mapStatus(op.status),
                errorMessage = op.errorMessage
            )
        }
    }

    private fun formatDate(timestamp: Long): String {
        val date = Date(timestamp)
        val format = SimpleDateFormat("yyyy-MM-dd HH:mm", Locale.getDefault())
        return format.format(date)
    }

    private fun mapStatus(status: SyncOperationStatus): SyncOperationUIModel.Status {
        return when (status) {
            SyncOperationStatus.PENDING -> SyncOperationUIModel.Status.PENDING
            SyncOperationStatus.IN_PROGRESS -> SyncOperationUIModel.Status.IN_PROGRESS
            SyncOperationStatus.FAILED -> SyncOperationUIModel.Status.FAILED
        }
    }

    data class SyncOperationUIModel(
        val id: String,
        val entityType: String,
        val operationType: String,
        val entityTitle: String?,
        val localId: String,
        val serverId: String?,
        val createdAt: String,
        val status: Status,
        val errorMessage: String?
    ) {
        enum class Status(val displayName: String) {
            PENDING("Pending"),
            IN_PROGRESS("In Progress"),
            FAILED("Failed")
        }
    }
}
