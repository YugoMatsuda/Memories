import SwiftUI
import Domains
import UILogics

public struct SyncQueuesView: View {
    @StateObject private var viewModel: SyncQueuesViewModel

    public init(viewModel: SyncQueuesViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        List {
            if viewModel.operations.isEmpty {
                Text("No pending operations")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.operations, id: \.id) { operation in
                    operationRow(operation)
                }
            }
        }
        .navigationTitle("Sync Queues")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.onAppear()
        }
    }

    private func operationRow(_ operation: SyncOperation) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(operation.entityType.displayName)
                    .font(.headline)
                Text(operation.operationType.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let errorMessage = operation.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Spacer()

            statusBadge(operation.status)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func statusBadge(_ status: SyncOperationStatus) -> some View {
        Text(status.displayName)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.2))
            .foregroundStyle(status.color)
            .clipShape(Capsule())
    }
}

// MARK: - Display Extensions

extension EntityType {
    var displayName: String {
        switch self {
        case .album:
            return "Album"
        case .memory:
            return "Memory"
        case .user:
            return "User"
        }
    }
}

extension OperationType {
    var displayName: String {
        switch self {
        case .create:
            return "Create"
        case .update:
            return "Update"
        }
    }
}

extension SyncOperationStatus {
    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .inProgress:
            return "In Progress"
        case .failed:
            return "Failed"
        }
    }

    var color: Color {
        switch self {
        case .pending:
            return .orange
        case .inProgress:
            return .blue
        case .failed:
            return .red
        }
    }
}
