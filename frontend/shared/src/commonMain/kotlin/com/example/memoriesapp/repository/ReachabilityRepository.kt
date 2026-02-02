package com.example.memoriesapp.repository

import kotlinx.coroutines.flow.Flow

/**
 * Repository interface for network reachability status
 */
interface ReachabilityRepository {
    val isConnected: Boolean
    val isConnectedFlow: Flow<Boolean>
}
