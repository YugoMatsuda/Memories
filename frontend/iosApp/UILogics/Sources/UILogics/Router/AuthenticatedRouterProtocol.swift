import Foundation
import Domains

public enum AuthenticatedRoute: Hashable {
    case userProfile(User)
}

@MainActor
public protocol AuthenticatedRouterProtocol: AnyObject {
    func push(_ route: AuthenticatedRoute)
    func pop()
    func popToRoot()
}
