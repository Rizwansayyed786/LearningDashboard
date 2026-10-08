import Foundation
import Observation

@MainActor
@Observable
final class DashboardViewModel {
    private(set) var state: DashboardState = .idle

    private let getCoursesUseCase: GetCoursesUseCase

    init(getCoursesUseCase: GetCoursesUseCase) {
        self.getCoursesUseCase = getCoursesUseCase
    }

    /// Called from `.task`; runs once so returning from details doesn't reload.
    func loadIfNeeded() async {
        guard case .idle = state else { return }
        await load()
    }

    /// Full reload with a loading indicator (initial load, "Try Again").
    func load() async {
        state = .loading
        await fetch()
    }

    /// Pull-to-refresh: keeps showing the current list instead of flashing a spinner.
    func refresh() async {
        if case .loaded = state {
            await fetch()
        } else {
            await load()
        }
    }

    /// Keeps the list in sync when a lesson is completed on the details screen.
    func apply(updated course: Course) {
        guard case .loaded(var courses, let isFromCache) = state,
              let index = courses.firstIndex(where: { $0.id == course.id }) else { return }
        courses[index] = course
        state = .loaded(courses: courses, isFromCache: isFromCache)
    }

    private func fetch() async {
        do {
            let result = try await getCoursesUseCase.execute()
            state = result.courses.isEmpty
                ? .empty
                : .loaded(courses: result.courses, isFromCache: result.isFromCache)
        } catch is CancellationError {
            // View went away mid-load: reset so the next appearance starts again.
            if case .loading = state { state = .idle }
        } catch {
            state = .error(error.userMessage)
        }
    }
}
