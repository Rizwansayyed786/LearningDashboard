import SwiftUI

/// Switches between the login screen and the authenticated NavigationStack.
struct RootView: View {
    let container: AppContainer
    @State private var user: User?

    var body: some View {
        if let user {
            NavigationStack {
                DashboardView(container: container, user: user, onLogout: { self.user = nil })
            }
        } else {
            LoginView(
                viewModel: container.makeLoginViewModel(),
                onLoginSuccess: { self.user = $0 }
            )
        }
    }
}
