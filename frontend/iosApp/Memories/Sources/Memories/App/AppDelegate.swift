import Foundation
import UIKit

@MainActor
public class AppDelegate: NSObject, UIApplicationDelegate {
    public let rootViewModel = RootViewModel()

    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        rootViewModel.initialize()
        return true
    }
}
