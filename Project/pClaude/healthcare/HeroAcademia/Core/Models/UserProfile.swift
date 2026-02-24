import Foundation
import FirebaseFirestore

enum Gender: String, Codable, CaseIterable {
    case male
    case female
    case other

    var displayName: String {
        switch self {
        case .male: return "男性"
        case .female: return "女性"
        case .other: return "その他"
        }
    }
}

struct UserProfile: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var email: String
    var displayName: String
    var height: Double?
    var birthday: Date?
    var gender: Gender?

    init(
        id: String? = nil,
        email: String,
        displayName: String,
        height: Double? = nil,
        birthday: Date? = nil,
        gender: Gender? = nil
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.height = height
        self.birthday = birthday
        self.gender = gender
    }
}
