package com.example.memoriesapp.data.repository

import com.example.memoriesapp.repository.ReachabilityRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Mock implementation of ReachabilityRepository.
 * Always returns true (online) for simplicity.
 */
class ReachabilityRepositoryImpl : ReachabilityRepository {
    private val _isConnectedFlow = MutableStateFlow(true)

    override val isConnected: Boolean
        get() = _isConnectedFlow.value

    override val isConnectedFlow: Flow<Boolean> = _isConnectedFlow.asStateFlow()
}
