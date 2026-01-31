import Foundation
import SwiftUI
import Domains

@MainActor
public final class UserProfileViewModel: ObservableObject {
    @Published public var name: String
    @Published public var birthday: Date?
    @Published public var selectedImage: UIImage?
    @Published public var isShowingImagePicker = false

    public let username: String
    public let avatarUrl: URL?

    private let user: User

    public init(user: User) {
        self.user = user
        self.name = user.name
        self.username = user.username
        self.birthday = user.birthday
        self.avatarUrl = user.avatarUrl
    }

    public func selectAvatar() {
        isShowingImagePicker = true
    }

    public func save() {
        // TODO: Implement save logic
    }
}
