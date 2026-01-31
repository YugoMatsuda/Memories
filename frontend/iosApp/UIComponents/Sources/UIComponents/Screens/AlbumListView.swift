import SwiftUI
import UILogics
import SDWebImageSwiftUI

public struct AlbumListView: View {
    @StateObject private var viewModel: AlbumListViewModel

    public init(viewModel: AlbumListViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack {
            Text("Albums")
        }
        .navigationTitle("Memories")
        .toolbar {
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
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                        }
                    }
                }
            }
        }
    }
}
