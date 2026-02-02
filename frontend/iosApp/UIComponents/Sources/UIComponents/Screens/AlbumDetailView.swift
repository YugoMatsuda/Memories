import SwiftUI
import UILogics
import SDWebImageSwiftUI

public struct AlbumDetailView: View {
    @StateObject private var viewModel: AlbumDetailViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    public init(viewModel: AlbumDetailViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        ZStack {
            contentView

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    fabButton
                }
            }
            .padding()
        }
        .navigationTitle(viewModel.album.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.showEditAlbumForm()
                } label: {
                    Image(systemName: "pencil")
                }
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
        .fullScreenCover(isPresented: showViewerBinding) {
            if case .success(let listData) = viewModel.displayResult {
                MemoryViewerView(
                    viewerMemoryId: $viewModel.viewerMemoryId,
                    items: listData.items
                )
            }
        }
    }

    private var showViewerBinding: Binding<Bool> {
        Binding(
            get: { viewModel.viewerMemoryId != nil },
            set: { if !$0 { viewModel.closeMemoryViewer() } }
        )
    }

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.displayResult {
        case .loading:
            ProgressView()
        case .success(let listData):
            memoryGridView(listData: listData)
        case .failure(let error):
            errorView(error: error)
        }
    }

    @ViewBuilder
    private func memoryGridView(listData: AlbumDetailViewModel.ListData) -> some View {
        if listData.items.isEmpty {
            EmptyStateView(
                icon: "photo.stack",
                title: "No memories yet",
                message: "Tap + to add your first memory"
            )
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(listData.items) { item in
                        memoryCell(item: item)
                            .onAppear {
                                if item.id == listData.items.last?.id {
                                    viewModel.onLoadMore()
                                }
                            }
                    }
                }
                .padding(.horizontal)

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
    }

    private func memoryCell(item: AlbumDetailViewModel.MemoryItemUIModel) -> some View {
        Button {
            item.didTap()
        } label: {
            WebImage(url: item.displayImage)
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0, maxWidth: .infinity)
                .aspectRatio(2/3, contentMode: .fit)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func errorView(error: AlbumDetailViewModel.ErrorUIModel) -> some View {
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
            viewModel.showCreateMemoryForm()
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
}
