import Foundation
import Domains

public enum AuthenticatedRoute: Hashable {
    case userProfile(User)
    case albumDetail(Album)
}

public enum AlbumFormMode: Equatable {
    case create
    case edit(Album)
}

public enum AuthenticatedSheet: Identifiable, Equatable {
    case albumForm(AlbumFormMode)

    public var id: String {
        switch self {
        case .albumForm(let mode):
            switch mode {
            case .create:
                return "albumForm_create"
            case .edit(let album):
                return "albumForm_edit_\(album.id)"
            }
        }
    }
}

@MainActor
public protocol AuthenticatedRouterProtocol: AnyObject {
    var sheetItem: AuthenticatedSheet? { get set }
    func push(_ route: AuthenticatedRoute)
    func pop()
    func popToRoot()
    func showSheet(_ sheet: AuthenticatedSheet)
    func dismissSheet()
}
