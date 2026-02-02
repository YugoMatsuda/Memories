import Foundation
import Shared

// Type alias for KMP User
public typealias User = Shared.User

// MARK: - LocalDate <-> Date Conversion

extension Kotlinx_datetimeLocalDate {
    /// Convert KMP LocalDate to Swift Date (midnight UTC)
    public var date: Date {
        var components = DateComponents()
        components.year = Int(year)
        components.month = Int(monthNumber)
        components.day = Int(dayOfMonth)
        components.timeZone = TimeZone(identifier: "UTC")
        return Calendar.current.date(from: components) ?? Date()
    }

    /// Create LocalDate from Swift Date
    public static func from(date: Date) -> Kotlinx_datetimeLocalDate {
        let calendar = Calendar.current
        let year = Int32(calendar.component(.year, from: date))
        let month = Int32(calendar.component(.month, from: date))
        let day = Int32(calendar.component(.day, from: date))
        return Kotlinx_datetimeLocalDate(year: year, monthNumber: month, dayOfMonth: day)
    }
}

// MARK: - Swift-friendly extensions for KMP User

extension Shared.User {
    // MARK: - Swift Type Accessors

    /// Birthday as Swift Date
    public var birthdayDate: Date? {
        birthday?.date
    }

    /// Avatar URL as Swift URL
    public var avatarURL: URL? {
        avatarUrl?.url
    }

    /// Avatar local path as file URL
    public var avatarLocalURL: URL? {
        avatarLocalPath.map { URL(fileURLWithPath: $0) }
    }

    /// Display avatar as Swift URL (for UI)
    public var displayAvatarURL: URL? {
        if let remote = avatarUrl { return URL(string: remote) }
        if let local = avatarLocalPath { return URL(fileURLWithPath: local) }
        return nil
    }

    // MARK: - Convenience Initializer

    /// Create User with Swift types
    public static func create(
        id: Int,
        name: String,
        username: String,
        birthday: Date? = nil,
        avatarUrl: URL? = nil,
        avatarLocalPath: String? = nil,
        syncStatus: Shared.SyncStatus = .synced
    ) -> Shared.User {
        Shared.User(
            id: Int32(id),
            name: name,
            username: username,
            birthday: birthday.map { Kotlinx_datetimeLocalDate.from(date: $0) },
            avatarUrl: avatarUrl?.absoluteString,
            avatarLocalPath: avatarLocalPath,
            syncStatus: syncStatus
        )
    }

    // MARK: - Copy helpers (Swift-style)

    public func with(
        name: String? = nil,
        birthday: OptionalUpdate<Date> = .noChange,
        avatarUrl: OptionalUpdate<URL> = .noChange,
        avatarLocalPath: OptionalUpdate<String> = .noChange,
        syncStatus: Shared.SyncStatus? = nil
    ) -> Shared.User {
        let newBirthday: Kotlinx_datetimeLocalDate?
        switch birthday {
        case .noChange:
            newBirthday = self.birthday
        case .setNil:
            newBirthday = nil
        case .set(let date):
            newBirthday = Kotlinx_datetimeLocalDate.from(date: date)
        }

        let newAvatarUrl: String?
        switch avatarUrl {
        case .noChange:
            newAvatarUrl = self.avatarUrl
        case .setNil:
            newAvatarUrl = nil
        case .set(let url):
            newAvatarUrl = url.absoluteString
        }

        let newAvatarLocalPath: String?
        switch avatarLocalPath {
        case .noChange:
            newAvatarLocalPath = self.avatarLocalPath
        case .setNil:
            newAvatarLocalPath = nil
        case .set(let path):
            newAvatarLocalPath = path
        }

        return Shared.User(
            id: self.id,
            name: name ?? self.name,
            username: self.username,
            birthday: newBirthday,
            avatarUrl: newAvatarUrl,
            avatarLocalPath: newAvatarLocalPath,
            syncStatus: syncStatus ?? self.syncStatus
        )
    }
}

// MARK: - Protocol Conformances
// Note: Hashable and Equatable are inherited from Kotlin/NSObject

extension Shared.User: @retroactive Identifiable {}
