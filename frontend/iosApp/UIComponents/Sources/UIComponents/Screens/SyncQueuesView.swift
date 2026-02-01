import SwiftUI
import UILogics

public struct SyncQueuesView: View {
    @StateObject private var viewModel: SyncQueuesViewModel

    public init(viewModel: SyncQueuesViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        List {
            if viewModel.items.isEmpty {
                Text("No pending operations")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.items) { item in
                    operationRow(item)
                }
            }
        }
        .navigationTitle("Sync Queues")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.onAppear()
        }
    }

    private func operationRow(_ item: SyncQueuesViewModel.SyncOperationUIModel) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.entityType)
                    .font(.headline)
                Text(item.operationType)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let errorMessage = item.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Spacer()

            statusBadge(item.status)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func statusBadge(_ status: SyncQueuesViewModel.SyncOperationUIModel.Status) -> some View {
        Text(status.displayName)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.2))
            .foregroundStyle(status.color)
            .clipShape(Capsule())
    }
}

// MARK: - Status Color

extension SyncQueuesViewModel.SyncOperationUIModel.Status {
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
