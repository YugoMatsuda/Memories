import SwiftUI
import Memories

@main
struct iOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            RootView(viewModel: delegate.rootViewModel)
        }
    }
}
