import SwiftUI

struct LoginView: View {
    @State private var viewModel: LoginViewModel
    private let onLoginSuccess: (User) -> Void

    init(viewModel: LoginViewModel, onLoginSuccess: @escaping (User) -> Void) {
        // State only keeps the first value, so VMs created by later re-inits are discarded.
        _viewModel = State(initialValue: viewModel)
        self.onLoginSuccess = onLoginSuccess
    }

    var body: some View {
        @Bindable var model = viewModel

        VStack(spacing: 20) {
            Spacer()

            VStack(spacing: 6) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.tint)
                Text("Learning Dashboard")
                    .font(.title.bold())
                Text("Sign in to continue")
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 14) {
                field(error: model.emailError) {
                    TextField("Email", text: $model.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                field(error: model.passwordError) {
                    SecureField("Password", text: $model.password)
                        .textContentType(.password)
                        .onSubmit { Task { await model.login() } }
                }
            }

            if case .error(let message) = model.state {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await model.login() }
            } label: {
                Group {
                    if model.isLoading {
                        ProgressView()
                    } else {
                        Text("Log In").bold()
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 24)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(model.isLoading)

            Text("Demo: student@example.com / password123")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(24)
        .onChange(of: model.state) { _, newState in
            if case .success(let user) = newState { onLoginSuccess(user) }
        }
    }

    @ViewBuilder
    private func field<Content: View>(error: String?, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            content()
                .padding(12)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
            if let error {
                Text(error).font(.caption).foregroundStyle(.red)
            }
        }
    }
}
