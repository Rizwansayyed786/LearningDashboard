import Foundation
import Observation

@MainActor
@Observable
final class CourseDetailsViewModel {
    private(set) var state: CourseDetailsState = .idle
    /// Set when completing a lesson fails; shown as an alert.
    private(set) var actionError: String?

    private let courseId: Int
    private let getCourseDetailsUseCase: GetCourseDetailsUseCase
    private let completeLessonUseCase: CompleteLessonUseCase
    private let onCourseUpdated: (Course) -> Void
    private var lessonsInFlight: Set<Int> = []

    init(
        courseId: Int,
        getCourseDetailsUseCase: GetCourseDetailsUseCase,
        completeLessonUseCase: CompleteLessonUseCase,
        onCourseUpdated: @escaping (Course) -> Void
    ) {
        self.courseId = courseId
        self.getCourseDetailsUseCase = getCourseDetailsUseCase
        self.completeLessonUseCase = completeLessonUseCase
        self.onCourseUpdated = onCourseUpdated
    }

    func loadIfNeeded() async {
        guard case .idle = state else { return }
        await load()
    }

    func load() async {
        state = .loading
        do {
            state = .loaded(try await getCourseDetailsUseCase.execute(courseId: courseId))
        } catch is CancellationError {
            if case .loading = state { state = .idle }
        } catch {
            state = .error(error.userMessage)
        }
    }

    func completeLesson(_ lessonId: Int) async {
        guard case .loaded(let course) = state,
              let lesson = course.lessons.first(where: { $0.id == lessonId }),
              !lesson.isCompleted,
              lessonsInFlight.insert(lessonId).inserted else { return }
        defer { lessonsInFlight.remove(lessonId) }

        do {
            let updated = try await completeLessonUseCase.execute(courseId: courseId, lessonId: lessonId)
            state = .loaded(updated)
            onCourseUpdated(updated)
        } catch is CancellationError {
            // Nothing to do; state is unchanged.
        } catch {
            actionError = error.userMessage
        }
    }

    func dismissActionError() {
        actionError = nil
    }
}
