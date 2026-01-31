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
            VStack {
                Text("Albums")
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    fabButton
                }
            }
            .padding()
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
}
