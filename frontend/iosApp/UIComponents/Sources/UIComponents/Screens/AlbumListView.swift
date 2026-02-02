import SwiftUI
import UILogics
import SDWebImageSwiftUI

public struct AlbumListView: View {
    @StateObject private var viewModel: AlbumListViewModel

    public init(viewModel: AlbumListViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        ZStack {
            contentView

            VStack {
                Spacer()
                HStack {
                    if viewModel.isNetworkDebugMode {
                        networkToggleButton
                    }
                    Spacer()
                    fabButton
                }
            }
            .padding()
        }
        .navigationTitle(viewModel.isNetworkDebugMode ? "Memories (Debug)" : "Memories")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.isNetworkDebugMode {
                ToolbarItem(placement: .topBarLeading) {
                    syncButton
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if let userIcon = viewModel.userIcon {
                    Button {
                        userIcon.didTap()
                    } label: {
                        if let avatarUrl = userIcon.avatarUrl {
                            WebImage(url: avatarUrl)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 32, height: 32)
                                .clipped()
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                        }
                    }
                }
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.displayResult {
        case .loading:
            ProgressView()
        case .success(let listData):
            albumListView(listData: listData)
        case .failure(let error):
            errorView(error: error)
        }
    }

    @ViewBuilder
    private func albumListView(listData: AlbumListViewModel.ListData) -> some View {
        if listData.items.isEmpty {
            EmptyStateView(
                icon: "photo.on.rectangle.angled",
                title: "No albums yet",
                message: "Tap + to create your first album"
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(listData.items) { item in
                        albumRow(item: item)
                            .onAppear {
                                if item.id == listData.items.last?.id {
                                    viewModel.onLoadMore()
                                }
                            }
                        Divider()
                    }

                    if listData.hasMore {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .onAppear {
                                viewModel.onLoadMore()
                            }
                    }
                }
            }
            .refreshable {
                await viewModel.onRefresh()
            }
        }
    }

    private func albumRow(item: AlbumListViewModel.AlbumItemUIModel) -> some View {
        Button {
            item.didTap()
        } label: {
            HStack(spacing: 12) {
                if let url = item.coverImageUrl {
                    WebImage(url: url)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        }
                }

                Text(item.title)
                    .font(.body)
                    .foregroundStyle(.primary)

                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func errorView(error: AlbumListViewModel.ErrorUIModel) -> some View {
        VStack(spacing: 16) {
            Text(error.message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Retry") {
                error.retryAction()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    private var fabButton: some View {
        Button {
            viewModel.showCreateAlbumForm()
        } label: {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.accentColor)
                .clipShape(Circle())
                .shadow(radius: 4, y: 2)
        }
    }

    @ViewBuilder
    private var syncButton: some View {
        Button {
            viewModel.showSyncQueues()
        } label: {
            HStack(spacing: 6) {
                if viewModel.syncState.isSyncing {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Syncing")
                        .font(.subheadline)
                } else {
                    Text("Sync Queues")
                        .font(.subheadline)
                    if viewModel.syncState.pendingCount > 0 {
                        Text("\(viewModel.syncState.pendingCount)")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private var networkToggleButton: some View {
        Button {
            viewModel.toggleOnlineState()
        } label: {
            Image(systemName: viewModel.isOnline ? "wifi" : "wifi.slash")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(viewModel.isOnline ? Color.green : Color.red)
                .clipShape(Circle())
                .shadow(radius: 4, y: 2)
        }
    }
}
