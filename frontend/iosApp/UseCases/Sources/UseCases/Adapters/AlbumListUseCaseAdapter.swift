import Foundation
import Combine
import Domains
import Repositories
import Utilities
@preconcurrency import Shared

// MARK: - Protocol

public protocol AlbumListUseCaseProtocol: Sendable {
    func observeUser() -> AnyPublisher<User, Never>
    func observeAlbumChange() -> AnyPublisher<Shared.LocalAlbumChangeEvent, Never>
    func observeSync() -> AnyPublisher<Shared.SyncQueueState, Never>
    func observeOnlineState() -> AnyPublisher<Bool, Never>
    func display() async -> Shared.AlbumDisplayResult
    func next(page: Int) async -> Shared.AlbumNextResult
    func toggleOnlineState()
}

// MARK: - Adapter

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

    public func observeAlbumChange() -> AnyPublisher<Shared.LocalAlbumChangeEvent, Never> {
        kmpUseCase.observeAlbumChange().asPublisher()
    }

    public func observeSync() -> AnyPublisher<Shared.SyncQueueState, Never> {
        kmpUseCase.observeSync().asPublisher()
    }

    public func observeOnlineState() -> AnyPublisher<Bool, Never> {
        kmpUseCase.observeOnlineState()
            .asPublisher()
            .map { $0.boolValue }
            .eraseToAnyPublisher()
    }

    // MARK: - Actions

    public func display() async -> Shared.AlbumDisplayResult {
        do {
            return try await kmpUseCase.display()
        } catch {
            return Shared.AlbumDisplayResult.Failure(error: .unknown)
        }
    }

    public func next(page: Int) async -> Shared.AlbumNextResult {
        do {
            return try await kmpUseCase.next(page: Int32(page))
        } catch {
            return Shared.AlbumNextResult.Failure(error: .unknown)
        }
    }

    public func toggleOnlineState() {
        guard let debugRepository = reachabilityRepository as? DebugReachabilityRepository else {
            fatalError("toggleOnlineState can only be called with DebugReachabilityRepository")
        }
        debugRepository.setOnline(!debugRepository.isConnected)
    }
}
