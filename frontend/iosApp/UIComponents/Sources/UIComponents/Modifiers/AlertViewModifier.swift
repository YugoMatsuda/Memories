import SwiftUI
import UILogics

public struct AlertViewModifier: ViewModifier {
    @Binding public var item: AlertItem?

    public init(item: Binding<AlertItem?>) {
        self._item = item
    }

    public func body(content: Content) -> some View {
        content
            .alert(item: $item) { item in
                if item.buttons.count == 2 {
                    return Alert(
                        title: Text(item.title),
                        message: Text(item.message),
                        primaryButton: item.buttons[0],
                        secondaryButton: item.buttons[1]
                    )
                } else if item.buttons.count == 1 {
                    return Alert(
                        title: Text(item.title),
                        message: Text(item.message),
                        dismissButton: item.buttons[0]
                    )
                } else {
                    return Alert(
                        title: Text(item.title),
                        message: Text(item.message),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
    }
}

public extension View {
    func showAlert(item: Binding<AlertItem?>) -> some View {
        self.modifier(AlertViewModifier(item: item))
    }
}
