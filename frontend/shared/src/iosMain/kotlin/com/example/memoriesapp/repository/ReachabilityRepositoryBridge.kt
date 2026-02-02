package com.example.memoriesapp.repository

import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow

/**
 * Callback interface for reachability changes
 */
interface ReachabilityChangeCallback {
    fun onReachabilityChanged(isConnected: Boolean)
}

/**
 * Bridge interface for Swift to implement
 */
interface ReachabilityRepositoryBridge {
    val isConnected: Boolean
    fun registerReachabilityCallback(callback: ReachabilityChangeCallback)
    fun unregisterReachabilityCallback()
}

/**
 * iOS implementation of ReachabilityRepository
 */
class ReachabilityRepositoryImpl(
    private val bridge: ReachabilityRepositoryBridge
) : ReachabilityRepository {

    private val _isConnectedFlow = MutableSharedFlow<Boolean>(
        replay = 1,
        extraBufferCapacity = 64,
        onBufferOverflow = BufferOverflow.DROP_OLDEST
    )

    override val isConnectedFlow: SharedFlow<Boolean> = _isConnectedFlow.asSharedFlow()

    init {
        bridge.registerReachabilityCallback(object : ReachabilityChangeCallback {
            override fun onReachabilityChanged(isConnected: Boolean) {
                _isConnectedFlow.tryEmit(isConnected)
            }
        })
    }

    override val isConnected: Boolean get() = bridge.isConnected
}
