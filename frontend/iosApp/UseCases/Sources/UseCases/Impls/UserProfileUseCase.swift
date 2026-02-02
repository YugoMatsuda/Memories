import Foundation
import Domains
import APIGateways
import APIClients
import Repositories
import Utilities

public struct UserProfileUseCase: UserProfileUseCaseProtocol, Sendable {
    private let userGateway: UserGatewayProtocol
    private let userRepository: UserRepositoryProtocol
    private let authSessionRepository: AuthSessionRepositoryProtocol
    private let syncQueueService: SyncQueueServiceProtocol
    private let reachabilityRepository: ReachabilityRepositoryProtocol
    private let imageStorageRepository: ImageStorageRepositoryProtocol

    public init(
        userGateway: UserGatewayProtocol,
        userRepository: UserRepositoryProtocol,
        authSessionRepository: AuthSessionRepositoryProtocol,
        syncQueueService: SyncQueueServiceProtocol,
        reachabilityRepository: ReachabilityRepositoryProtocol,
        imageStorageRepository: ImageStorageRepositoryProtocol
    ) {
        self.userGateway = userGateway
        self.userRepository = userRepository
        self.authSessionRepository = authSessionRepository
        self.syncQueueService = syncQueueService
        self.reachabilityRepository = reachabilityRepository
        self.imageStorageRepository = imageStorageRepository
    }

    public func updateProfile(name: String, birthday: Date?, avatarData: Data?) async -> UserProfileUseCaseModel.UpdateProfileResult {
        guard let currentUser = await userRepository.get() else {
            return .failure(.unknown)
        }

        let operationLocalId = UUID()

        // 1. Save avatar locally if provided
        var localAvatarPath: String? = currentUser.avatarLocalPath
        if let imageData = avatarData {
            do {
                localAvatarPath = try imageStorageRepository.save(imageData, entity: .avatar, localId: operationLocalId)
            } catch {
                return .failure(.imageStorageFailed)
            }
        }

        // 2. Update local DB (Optimistic)
        let updatedUser = currentUser.with(
            name: name,
            birthday: .from(birthday),
            avatarUrl: avatarData != nil ? .setNil : .noChange,
            avatarLocalPath: .from(localAvatarPath),
            syncStatus: .pendingUpdate
        )
        do {
            try await userRepository.set(updatedUser)
        } catch {
            return .failure(.databaseError)
        }

        // 3. If offline, enqueue and return
        guard reachabilityRepository.isConnected else {
            syncQueueService.enqueue(entityType: .user, operationType: .update, localId: operationLocalId)
            return .successPendingSync(updatedUser)
        }

        // 4. If online, sync immediately
        return await syncUpdate(user: updatedUser, avatarData: avatarData, operationLocalId: operationLocalId)
    }

    public func logout() {
        authSessionRepository.clearSession()
    }

    // MARK: - Private

    private func syncUpdate(user: User, avatarData: Data?, operationLocalId: UUID) async -> UserProfileUseCaseModel.UpdateProfileResult {
        do {
            // API call
            let birthdayString = user.birthday.map { DateFormatters.yyyyMMdd.string(from: $0) }
            var response = try await userGateway.updateUser(
                name: user.name,
                birthday: birthdayString,
                avatarUrl: nil
            )

            // Upload avatar if provided
            if let imageData = avatarData {
                response = try await userGateway.uploadAvatar(
                    fileData: imageData,
                    fileName: MimeType.jpeg.fileName(for: operationLocalId),
                    mimeType: MimeType.jpeg.rawValue
                )
                // Delete local image
                imageStorageRepository.delete(entity: .avatar, localId: operationLocalId)
            }

            // Update local DB
            let syncedUser = UserMapper.toDomain(response)
            do {
                try await userRepository.set(syncedUser)
            } catch {
                print("[UserProfileUseCase] Failed to save synced user to cache: \(error)")
            }
            return .success(syncedUser)
        } catch {
            // Sync failed, enqueue for later
            let failedUser = user.with(syncStatus: .failed)
            do {
                try await userRepository.set(failedUser)
            } catch {
                print("[UserProfileUseCase] Failed to save failed user to cache: \(error)")
            }
            syncQueueService.enqueue(entityType: .user, operationType: .update, localId: operationLocalId)
                return .successPendingSync(user)
        }
    }
}
