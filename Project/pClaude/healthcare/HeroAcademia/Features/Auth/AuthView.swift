import SwiftUI

struct AuthView: View {
    @Bindable var viewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // App title
            VStack(spacing: 8) {
                Text("HeroAcademia")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("体組成管理")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Form
            VStack(spacing: 16) {
                TextField("メールアドレス", text: $viewModel.email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .accessibilityIdentifier("emailField")

                SecureField("パスワード（6文字以上）", text: $viewModel.password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(viewModel.isLoginMode ? .password : .newPassword)
                    .accessibilityIdentifier("passwordField")

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task { await viewModel.submit() }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(viewModel.buttonTitle)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.isFormValid || viewModel.isLoading)
                .accessibilityIdentifier("submitButton")

                Button(viewModel.toggleTitle) {
                    viewModel.toggleMode()
                }
                .font(.footnote)
                .accessibilityIdentifier("toggleModeButton")
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .navigationTitle(viewModel.isLoginMode ? "ログイン" : "新規登録")
        .navigationBarTitleDisplayMode(.inline)
    }
}
