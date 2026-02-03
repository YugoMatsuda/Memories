package com.example.memoriesapp.repository.mock

import com.example.memoriesapp.repository.ReachabilityRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow

class MockReachabilityRepository : ReachabilityRepository {
    private val _isConnectedFlow = MutableStateFlow(true)

    override val isConnected: Boolean
        get() = _isConnectedFlow.value

    override val isConnectedFlow: Flow<Boolean> = _isConnectedFlow

    // Test helpers
    fun setConnected(connected: Boolean) {
        _isConnectedFlow.value = connected
    }
}
