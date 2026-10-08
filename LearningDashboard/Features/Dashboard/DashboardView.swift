import SwiftUI

@MainActor
struct DashboardView: View {
    @State private var viewModel: DashboardViewModel
    @State private var simulateOffline = false

    private let container: AppContainer
    private let user: User
    private let onLogout: () -> Void

    init(container: AppContainer, user: User, onLogout: @escaping () -> Void) {
        self.container = container
        self.user = user
        self.onLogout = onLogout
        _viewModel = State(initialValue: container.makeDashboardViewModel())
    }

    var body: some View {
        content
            .navigationTitle("My Courses")
            .navigationDestination(for: Int.self) { courseId in
                CourseDetailsView(
                    courseId: courseId,
                    container: container,
                    onCourseUpdated: { viewModel.apply(updated: $0) }
                )
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Log Out", action: onLogout)
                }
                #if DEBUG
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Toggle("Simulate offline", isOn: $simulateOffline)
                    } label: {
                        Image(systemName: "ladybug")
                    }
                }
                #endif
            }
            .onChange(of: simulateOffline) { _, isOffline in
                container.connectivity.setSimulatedOffline(isOffline)
            }
            .task { await viewModel.loadIfNeeded() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView("Loading courses…")

        case .loaded(let courses, let isFromCache):
            List {
                if isFromCache {
                    Section {
                        Label("Offline: showing your saved courses", systemImage: "icloud.slash")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }
                }
                Section("Welcome back, \(user.name)") {
                    ForEach(courses) { course in
                        NavigationLink(value: course.id) {
                            CourseCardView(course: course)
                        }
                    }
                }
            }
            .refreshable { await viewModel.refresh() }

        case .empty:
            ContentUnavailableView {
                Label("No Courses Yet", systemImage: "books.vertical")
            } description: {
                Text("Courses you enroll in will show up here.")
            } actions: {
                Button("Refresh") { Task { await viewModel.load() } }
            }

        case .error(let message):
            ContentUnavailableView {
                Label("Couldn't Load Courses", systemImage: "wifi.exclamationmark")
            } description: {
                Text(message)
            } actions: {
                Button("Try Again") { Task { await viewModel.load() } }
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}

private struct CourseCardView: View {
    let course: Course

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(course.title).font(.headline)
            Text(course.instructor)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ProgressView(value: Double(course.progress), total: 100) {
                Text("Progress: \(course.progress)%").font(.caption)
            }

            HStack {
                Text("\(course.totalLessons) lessons")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Continue")
                    .font(.footnote.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accentColor, in: Capsule())
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens course details")
    }
}
