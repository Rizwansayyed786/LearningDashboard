import XCTest
@testable import LearningDashboard

@MainActor
final class DashboardViewModelTests: XCTestCase {
    private func makeViewModel(_ result: Result<CoursesResult, Error>) -> DashboardViewModel {
        DashboardViewModel(
            getCoursesUseCase: GetCoursesUseCase(repository: StubCourseRepository(result: result))
        )
    }

    func testLoadedState() async {
        let courses = [TestData.course(id: 1, lessonCount: 4, completed: 1)]
        let viewModel = makeViewModel(.success(CoursesResult(courses: courses, isFromCache: false)))

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .loaded(courses: courses, isFromCache: false))
    }

    func testEmptyState() async {
        let viewModel = makeViewModel(.success(CoursesResult(courses: [], isFromCache: false)))

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .empty)
    }

    func testCachedCoursesAreFlagged() async {
        let courses = [TestData.course(id: 1, lessonCount: 4, completed: 0)]
        let viewModel = makeViewModel(.success(CoursesResult(courses: courses, isFromCache: true)))

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .loaded(courses: courses, isFromCache: true))
    }

    func testFailureExposesUserFacingMessage() async {
        let viewModel = makeViewModel(.failure(APIError.noCachedData))

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .error(APIError.noCachedData.errorDescription ?? ""))
    }

    func testApplyUpdatedCourseReplacesItInTheList() async {
        let original = TestData.course(id: 1, lessonCount: 4, completed: 0)
        let viewModel = makeViewModel(.success(CoursesResult(courses: [original], isFromCache: false)))
        await viewModel.load()

        var updated = original
        updated.lessons[0].isCompleted = true
        viewModel.apply(updated: updated)

        XCTAssertEqual(viewModel.state, .loaded(courses: [updated], isFromCache: false))
    }
}

private struct StubCourseRepository: CourseRepository {
    let result: Result<CoursesResult, Error>

    func getCourses() async throws -> CoursesResult { try result.get() }
    func getCourse(id: Int) async throws -> Course { throw APIError.notFound }
    func completeLesson(courseId: Int, lessonId: Int) async throws -> Course { throw APIError.notFound }
}
