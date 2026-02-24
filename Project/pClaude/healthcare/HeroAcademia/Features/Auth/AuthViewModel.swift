import Foundation
import FirebaseFirestore

@Observable
final class AuthViewModel {
    var email = ""
    var password = ""
    var isLoginMode = true
    var isLoading = false
    var errorMessage: String?

    private let firebaseService: FirebaseServiceProtocol

    init(firebaseService: FirebaseServiceProtocol) {
        self.firebaseService = firebaseService
    }

    var isFormValid: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        password.count >= 6
    }

    var buttonTitle: String {
        isLoginMode ? "ログイン" : "アカウント作成"
    }

    var toggleTitle: String {
        isLoginMode ? "アカウントをお持ちでない方" : "既にアカウントをお持ちの方"
    }

    func submit() async {
        guard isFormValid else { return }

        isLoading = true
        errorMessage = nil

        do {
            if isLoginMode {
                try await firebaseService.signIn(email: email, password: password)
            } else {
                try await firebaseService.signUp(email: email, password: password)
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func toggleMode() {
        isLoginMode.toggle()
        errorMessage = nil
    }
}
