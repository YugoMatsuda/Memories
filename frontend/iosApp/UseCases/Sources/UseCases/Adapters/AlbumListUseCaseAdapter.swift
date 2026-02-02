import Foundation
import Combine
import Domains
import Repositories
@preconcurrency import Shared

/// Adapter that wraps KMP AlbumListUseCase to conform to Swift AlbumListUseCaseProtocol
public final class AlbumListUseCaseAdapter: AlbumListUseCaseProtocol, @unchecked Sendable {
    private let kmpUseCase: Shared.AlbumListUseCase
    private let reachabilityRepository: ReachabilityRepositoryProtocol

    public init(
        kmpUseCase: Shared.AlbumListUseCase,
        reachabilityRepository: ReachabilityRepositoryProtocol
    ) {
        self.kmpUseCase = kmpUseCase
        self.reachabilityRepository = reachabilityRepository
    }

    // MARK: - Observe (KMP Flow → Swift Publisher)

    public func observeUser() -> AnyPublisher<User, Never> {
        kmpUseCase.observeUser().asPublisher()
    }

    public func observeAlbumChange() -> AnyPublisher<Repositories.LocalAlbumChangeEvent, Never> {
        kmpUseCase.observeAlbumChange()
            .asPublisher()
            .compactMap { kmpEvent -> Repositories.LocalAlbumChangeEvent? in
                if let created = kmpEvent as? Shared.LocalAlbumChangeEvent.Created {
                    return .created(created.album)
                } else if let updated = kmpEvent as? Shared.LocalAlbumChangeEvent.Updated {
                    return .updated(updated.album)
                }
                return nil
            }
            .eraseToAnyPublisher()
    }

    public func observeSync() -> AnyPublisher<Repositories.SyncQueueState, Never> {
        kmpUseCase.observeSync()
            .asPublisher()
            .map { kmpState in
                Repositories.SyncQueueState(
                    pendingCount: Int(kmpState.pendingCount),
                    isSyncing: kmpState.isSyncing
                )
            }
            .eraseToAnyPublisher()
    }

    public func observeOnlineState() -> AnyPublisher<Bool, Never> {
        kmpUseCase.observeOnlineState()
            .asPublisher()
            .map { $0.boolValue }
            .eraseToAnyPublisher()
    }

    // MARK: - Actions (delegated to KMP UseCase)

    public func display() async -> AlbumListUseCaseModel.DisplayResult {
        do {
            let result = try await kmpUseCase.display()
            if let success = result as? Shared.AlbumDisplayResult.Success {
                let pageInfo = AlbumListUseCaseModel.PageInfo(
                    albums: success.pageInfo.albums,
                    hasMore: success.pageInfo.hasMore
                )
                return .success(pageInfo)
            } else if let failure = result as? Shared.AlbumDisplayResult.Failure {
                return .failure(mapDisplayError(failure.error))
            }
            return .failure(.unknown)
        } catch {
            return .failure(.unknown)
        }
    }

    public func next(page: Int) async -> AlbumListUseCaseModel.NextResult {
        do {
            let result = try await kmpUseCase.next(page: Int32(page))
            if let success = result as? Shared.AlbumNextResult.Success {
                let pageInfo = AlbumListUseCaseModel.PageInfo(
                    albums: success.pageInfo.albums,
                    hasMore: success.pageInfo.hasMore
                )
                return .success(pageInfo)
            } else if let failure = result as? Shared.AlbumNextResult.Failure {
                return .failure(mapNextError(failure.error))
            }
            return .failure(.unknown)
        } catch {
            return .failure(.unknown)
        }
    }

    public func toggleOnlineState() {
        guard let debugRepository = reachabilityRepository as? DebugReachabilityRepository else {
            fatalError("toggleOnlineState can only be called with DebugReachabilityRepository")
        }
        debugRepository.setOnline(!debugRepository.isConnected)
    }

    // MARK: - Error Mapping

    private func mapDisplayError(_ error: Shared.AlbumDisplayError) -> AlbumListUseCaseModel.DisplayResult.Error {
        switch error {
        case .networkError: return .networkError
        case .offline: return .offline
        default: return .unknown
        }
    }

    private func mapNextError(_ error: Shared.AlbumNextError) -> AlbumListUseCaseModel.NextResult.Error {
        switch error {
        case .networkError: return .networkError
        case .offline: return .offline
        default: return .unknown
        }
    }
}
