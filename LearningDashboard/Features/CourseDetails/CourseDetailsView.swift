import SwiftUI

@MainActor
struct CourseDetailsView: View {
    @State private var viewModel: CourseDetailsViewModel

    init(courseId: Int, container: AppContainer, onCourseUpdated: @escaping (Course) -> Void) {
        _viewModel = State(
            initialValue: container.makeCourseDetailsViewModel(
                courseId: courseId,
                onCourseUpdated: onCourseUpdated
            )
        )
    }

    var body: some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .task { await viewModel.loadIfNeeded() }
            .alert("Couldn't Update Lesson", isPresented: errorAlertBinding) {
                Button("OK", role: .cancel) { viewModel.dismissActionError() }
            } message: {
                Text(viewModel.actionError ?? "")
            }
    }

    private var title: String {
        if case .loaded(let course) = viewModel.state { return course.title }
        return "Course"
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.actionError != nil },
            set: { if !$0 { viewModel.dismissActionError() } }
        )
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()

        case .loaded(let course):
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(course.instructor).foregroundStyle(.secondary)
                        ProgressView(value: Double(course.progress), total: 100)
                        Text("\(course.completedLessons) of \(course.totalLessons) lessons completed · \(course.progress)%")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("Lessons") {
                    ForEach(course.lessons) { lesson in
                        LessonRow(lesson: lesson) {
                            Task { await viewModel.completeLesson(lesson.id) }
                        }
                    }
                }
            }

        case .error(let message):
            ContentUnavailableView {
                Label("Couldn't Load Course", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Try Again") { Task { await viewModel.load() } }
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}

private struct LessonRow: View {
    let lesson: Lesson
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: lesson.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(lesson.isCompleted ? Color.green : Color.secondary)
                .accessibilityHidden(true)

            Text(lesson.title)

            Spacer()

            if lesson.isCompleted {
                Text("Completed")
                    .font(.caption)
                    .foregroundStyle(.green)
            } else {
                Button("Mark Complete", action: onComplete)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .animation(.default, value: lesson.isCompleted)
    }
}
