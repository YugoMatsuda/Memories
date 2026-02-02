import Foundation
import Combine
import Domains
import UseCases

@MainActor
public final class SyncQueuesViewModel: ObservableObject {
    @Published public private(set) var items: [SyncOperationUIModel] = []

    private let useCase: SyncQueuesUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()

    public init(useCase: SyncQueuesUseCaseProtocol) {
        self.useCase = useCase

        useCase.observeState()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task {
                    await self?.loadOperations()
                }
            }
            .store(in: &cancellables)
    }

    public func onAppear() {
        Task {
            await loadOperations()
        }
    }

    private func loadOperations() async {
        let queueItems = await useCase.getAll()
        items = queueItems.map { SyncOperationUIModel(from: $0) }
    }
}

// MARK: - UI Models

extension SyncQueuesViewModel {
    public struct SyncOperationUIModel: Identifiable, Equatable {
        public let id: UUID
        public let entityType: String
        public let operationType: String
        public let status: Status
        public let errorMessage: String?
        public let entityTitle: String?
        public let localId: String
        public let serverId: String?
        public let createdAt: String

        public init(from item: SyncQueueItem) {
            let operation = item.operation
            self.id = operation.idUUID
            self.entityType = Self.mapEntityType(operation.entityType)
            self.operationType = Self.mapOperationType(operation.operationType)
            self.status = Self.mapStatus(operation.status)
            self.errorMessage = operation.errorMessage
            self.entityTitle = item.entityTitle
            self.localId = String(operation.localIdUUID.uuidString.prefix(8)).lowercased()
            self.serverId = item.entityServerId.map { String($0) }
            self.createdAt = Self.formatDate(operation.createdAtDate)
        }

        private static func mapEntityType(_ type: EntityType) -> String {
            switch type {
            case .album: return "Album"
            case .memory: return "Memory"
            case .user: return "User"
            }
        }

        private static func mapOperationType(_ type: OperationType) -> String {
            switch type {
            case .create: return "Create"
            case .update: return "Update"
            }
        }

        private static func mapStatus(_ status: SyncOperationStatus) -> Status {
            switch status {
            case .pending: return .pending
            case .inProgress: return .inProgress
            case .failed: return .failed
            }
        }

        private static func formatDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .medium
            return formatter.string(from: date)
        }

        public enum Status: Equatable {
            case pending
            case inProgress
            case failed

            public var displayName: String {
                switch self {
                case .pending: return "Pending"
                case .inProgress: return "In Progress"
                case .failed: return "Failed"
                }
            }
        }
    }
}
