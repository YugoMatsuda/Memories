package com.example.memoriesapp.usecase.impl

import com.example.memoriesapp.core.LocalId
import com.example.memoriesapp.core.SyncStatus
import com.example.memoriesapp.domain.EntityType
import com.example.memoriesapp.domain.ImageEntityType
import com.example.memoriesapp.domain.MimeType
import com.example.memoriesapp.domain.OperationType
import com.example.memoriesapp.domain.User
import com.example.memoriesapp.gateway.UserGateway
import com.example.memoriesapp.mapper.UserMapper
import com.example.memoriesapp.repository.AuthSessionRepository
import com.example.memoriesapp.repository.ImageStorageRepository
import com.example.memoriesapp.repository.ReachabilityRepository
import com.example.memoriesapp.repository.UserRepository
import com.example.memoriesapp.usecase.SyncQueueService
import com.example.memoriesapp.usecase.UpdateProfileError
import com.example.memoriesapp.usecase.UpdateProfileResult
import com.example.memoriesapp.usecase.UserProfileUseCase
import kotlinx.datetime.LocalDate

/**
 * UseCase for user profile screen
 */
class UserProfileUseCaseImpl(
    private val userGateway: UserGateway,
    private val userRepository: UserRepository,
    private val authSessionRepository: AuthSessionRepository,
    private val syncQueueService: SyncQueueService,
    private val reachabilityRepository: ReachabilityRepository,
    private val imageStorageRepository: ImageStorageRepository
) : UserProfileUseCase {
    override suspend fun updateProfile(name: String, birthday: LocalDate?, avatarData: ByteArray?): UpdateProfileResult {
        val currentUser = userRepository.get()
            ?: return UpdateProfileResult.Failure(UpdateProfileError.UNKNOWN)

        val operationLocalId = LocalId.generate()

        // 1. Save avatar locally if provided
        var localAvatarPath: String? = currentUser.avatarLocalPath
        if (avatarData != null) {
            try {
                localAvatarPath = imageStorageRepository.save(avatarData, ImageEntityType.AVATAR, operationLocalId)
            } catch (e: Exception) {
                return UpdateProfileResult.Failure(UpdateProfileError.IMAGE_STORAGE_FAILED)
            }
        }

        // 2. Update local DB (Optimistic)
        val updatedUser = User(
            id = currentUser.id,
            name = name,
            username = currentUser.username,
            birthday = birthday,
            avatarUrl = if (avatarData != null) null else currentUser.avatarUrl,
            avatarLocalPath = localAvatarPath,
            syncStatus = SyncStatus.PENDING_UPDATE
        )
        try {
            userRepository.set(updatedUser)
        } catch (e: Exception) {
            return UpdateProfileResult.Failure(UpdateProfileError.DATABASE_ERROR)
        }

        // 3. If offline, enqueue and return
        if (!reachabilityRepository.isConnected) {
            syncQueueService.enqueue(EntityType.USER, OperationType.UPDATE, operationLocalId)
            return UpdateProfileResult.SuccessPendingSync(updatedUser)
        }

        // 4. If online, sync immediately
        return syncUpdate(updatedUser, avatarData, operationLocalId)
    }

    override fun logout() {
        authSessionRepository.clearSession()
    }

    private suspend fun syncUpdate(user: User, avatarData: ByteArray?, operationLocalId: LocalId): UpdateProfileResult {
        return try {
            // API call
            var response = userGateway.updateUser(
                name = user.name,
                birthday = user.birthday?.toString(),
                avatarUrl = null
            )

            // Upload avatar if provided
            if (avatarData != null) {
                response = userGateway.uploadAvatar(
                    fileData = avatarData,
                    fileName = MimeType.JPEG.fileName(operationLocalId),
                    mimeType = MimeType.JPEG.value
                )
                // Delete local image
                imageStorageRepository.delete(ImageEntityType.AVATAR, operationLocalId)
            }

            // Update local DB
            val syncedUser = UserMapper.toDomain(response)
            try {
                userRepository.set(syncedUser)
            } catch (e: Exception) {
                println("[UserProfileUseCase] Failed to save synced user to cache: $e")
            }
            UpdateProfileResult.Success(syncedUser)
        } catch (e: Exception) {
            // Sync failed, enqueue for later
            val failedUser = user.copy(syncStatus = SyncStatus.FAILED)
            try {
                userRepository.set(failedUser)
            } catch (updateError: Exception) {
                println("[UserProfileUseCase] Failed to save failed user to cache: $updateError")
            }
            syncQueueService.enqueue(EntityType.USER, OperationType.UPDATE, operationLocalId)
            UpdateProfileResult.SuccessPendingSync(user)
        }
    }
}
