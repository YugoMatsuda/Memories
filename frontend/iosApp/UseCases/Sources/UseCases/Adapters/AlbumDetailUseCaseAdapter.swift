import Foundation
import Combine
import Domains
import Repositories
import Utilities
@preconcurrency import Shared

// MARK: - Protocol

public protocol AlbumDetailUseCaseProtocol: Sendable {
    func display(album: Album) async -> Shared.MemoryDisplayResult
    func next(album: Album, page: Int) async -> Shared.MemoryNextResult
    func resolveAlbum(serverId: Int) async -> Shared.ResolveAlbumResult
    var localChangePublisher: AnyPublisher<Shared.LocalMemoryChangeEvent, Never> { get }
    var observeAlbumUpdate: AnyPublisher<Shared.LocalAlbumChangeEvent, Never> { get }
}

// MARK: - Adapter

public final class AlbumDetailUseCaseAdapter: AlbumDetailUseCaseProtocol, @unchecked Sendable {
    private let kmpUseCase: Shared.AlbumDetailUseCase

    public init(kmpUseCase: Shared.AlbumDetailUseCase) {
        self.kmpUseCase = kmpUseCase
    }

    // MARK: - Observe (KMP Flow → Swift Publisher)

    public var localChangePublisher: AnyPublisher<Shared.LocalMemoryChangeEvent, Never> {
        kmpUseCase.localChangeFlow.asPublisher()
    }

    public var observeAlbumUpdate: AnyPublisher<Shared.LocalAlbumChangeEvent, Never> {
        kmpUseCase.observeAlbumUpdate.asPublisher()
    }

    // MARK: - Actions

    public func display(album: Album) async -> Shared.MemoryDisplayResult {
        do {
            return try await kmpUseCase.display(album: album)
        } catch {
            return Shared.MemoryDisplayResult.Failure(error: .unknown)
        }
    }

    public func next(album: Album, page: Int) async -> Shared.MemoryNextResult {
        do {
            return try await kmpUseCase.next(album: album, page: Int32(page))
        } catch {
            return Shared.MemoryNextResult.Failure(error: .unknown)
        }
    }

    public func resolveAlbum(serverId: Int) async -> Shared.ResolveAlbumResult {
        do {
            return try await kmpUseCase.resolveAlbum(serverId: Int32(serverId))
        } catch {
            return Shared.ResolveAlbumResult.Failure(error: .networkError)
        }
    }
}
