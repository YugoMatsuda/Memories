import SwiftUI

public struct AlertItem: Equatable, Identifiable {
    public let id: String = UUID().uuidString
    public let title: String
    public let message: String
    public let buttons: [Alert.Button]

    public init(
        title: String,
        message: String,
        buttons: [Alert.Button]
    ) {
        self.title = title
        self.message = message
        self.buttons = buttons
    }

    public static func == (lhs: AlertItem, rhs: AlertItem) -> Bool {
        lhs.title == rhs.title && lhs.message == rhs.message
    }
}
