import Foundation

@MainActor
@Observable
final class BadgeViewModel {
    var earnedBadges: [Badge] = []
    var isLoading = false
    var errorMessage: String?

    private let firebaseService: FirebaseServiceProtocol

    init(firebaseService: FirebaseServiceProtocol) {
        self.firebaseService = firebaseService
    }

    var allBadgeTypes: [BadgeType] {
        BadgeType.allCases
    }

    func isEarned(_ type: BadgeType) -> Bool {
        earnedBadges.contains { $0.type == type }
    }

    func earnedDate(for type: BadgeType) -> Date? {
        earnedBadges.first { $0.type == type }?.earnedDate
    }

    func loadBadges() async {
        isLoading = true
        do {
            earnedBadges = try await firebaseService.fetchBadges()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
