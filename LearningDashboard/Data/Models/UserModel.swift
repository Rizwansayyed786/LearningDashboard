import Foundation

struct UserModel: Codable, Equatable, Sendable {
    let id: Int
    let name: String

    func toDomain() -> User {
        User(id: id, name: name)
    }
}
