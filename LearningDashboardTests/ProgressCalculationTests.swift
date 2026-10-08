import XCTest
@testable import LearningDashboard

final class ProgressCalculationTests: XCTestCase {
    private func progress(_ completed: Int, of total: Int) -> Int {
        ProgressCalculator.calculateProgress(completedLessons: completed, totalLessons: total)
    }

    func testQuarterSteps() {
        XCTAssertEqual(progress(0, of: 4), 0)
        XCTAssertEqual(progress(1, of: 4), 25)
        XCTAssertEqual(progress(2, of: 4), 50)
        XCTAssertEqual(progress(4, of: 4), 100)
    }

    func testZeroTotalLessonsReturnsZero() {
        XCTAssertEqual(progress(0, of: 0), 0)
    }

    func testResultIsTruncatedNotRounded() {
        XCTAssertEqual(progress(1, of: 3), 33)
        XCTAssertEqual(progress(2, of: 3), 66)
    }

    func testNoFloatingPointDrift() {
        // Int(Double(29) / 100 * 100) == 28 with floating-point math.
        XCTAssertEqual(progress(29, of: 100), 29)
        XCTAssertEqual(progress(57, of: 100), 57)
    }

    func testOutOfRangeInputIsClamped() {
        XCTAssertEqual(progress(5, of: 4), 100)
        XCTAssertEqual(progress(-1, of: 4), 0)
    }

    func testCourseProgressIsDerivedFromLessons() {
        var course = TestData.course(id: 1, lessonCount: 4, completed: 2)
        XCTAssertEqual(course.progress, 50)

        course.lessons[2].isCompleted = true
        XCTAssertEqual(course.progress, 75)
    }
}

enum TestData {
    static func course(id: Int, lessonCount: Int, completed: Int) -> Course {
        Course(
            id: id,
            title: "Course \(id)",
            instructor: "Instructor",
            lessons: (0..<lessonCount).map {
                Lesson(id: id * 100 + $0 + 1, title: "Lesson \($0 + 1)", isCompleted: $0 < completed)
            }
        )
    }

    static func models(completedInFirst: Int = 0) -> [CourseModel] {
        [
            CourseModel(course(id: 1, lessonCount: 4, completed: completedInFirst)),
            CourseModel(course(id: 2, lessonCount: 3, completed: 0))
        ]
    }
}
