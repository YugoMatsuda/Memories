package com.example.memoriesapp.data.repository

import com.example.memoriesapp.repository.ReachabilityRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Debug implementation of ReachabilityRepository.
 * Allows manually setting online/offline state for testing.
 */
class DebugReachabilityRepository(
    initialState: Boolean = true
) : ReachabilityRepository {

    private val _isConnectedFlow = MutableStateFlow(initialState)

    override val isConnected: Boolean
        get() = _isConnectedFlow.value

    override val isConnectedFlow: Flow<Boolean> = _isConnectedFlow.asStateFlow()

    fun setOnline(isOnline: Boolean) {
        _isConnectedFlow.value = isOnline
    }
}
