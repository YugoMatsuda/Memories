import SwiftUI
import UILogics

public struct AlbumDetailView: View {
    @StateObject private var viewModel: AlbumDetailViewModel

    public init(viewModel: AlbumDetailViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        Text(viewModel.album.title)
            .navigationTitle(viewModel.album.title)
    }
}
