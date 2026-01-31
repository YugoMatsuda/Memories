import SwiftUI
import UILogics

public struct AlbumDetailView: View {
    @StateObject private var viewModel: AlbumDetailViewModel

    public init(viewModel: AlbumDetailViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        ZStack {
            Text(viewModel.album.title)

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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.showEditAlbumForm()
                } label: {
                    Image(systemName: "pencil")
                }
            }
        }
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
