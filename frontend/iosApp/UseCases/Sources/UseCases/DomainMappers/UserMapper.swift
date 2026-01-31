import Foundation
import Domains
import APIGateways
import Utilities

public enum UserMapper {
    public static func toDomain(_ response: UserResponse) -> User {
        User(
            id: response.id,
            name: response.name,
            username: response.username,
            birthday: response.birthday.flatMap { DateFormatters.yyyyMMdd.date(from: $0) },
            avatarUrl: response.avatarUrl.flatMap { URL(string: $0) }
        )
    }
}
