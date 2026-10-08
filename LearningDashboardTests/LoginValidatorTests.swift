import XCTest
@testable import LearningDashboard

final class LoginValidatorTests: XCTestCase {
    private let validator = LoginValidator()

    func testEmailValidation() {
        XCTAssertEqual(validator.validateEmail(""), .emptyEmail)
        XCTAssertEqual(validator.validateEmail("   "), .emptyEmail)
        XCTAssertEqual(validator.validateEmail("not-an-email"), .invalidEmail)
        XCTAssertEqual(validator.validateEmail("a@b"), .invalidEmail)
        XCTAssertNil(validator.validateEmail("student@example.com"))
    }

    func testPasswordValidation() {
        XCTAssertEqual(validator.validatePassword(""), .emptyPassword)
        XCTAssertEqual(validator.validatePassword("12345"), .passwordTooShort)
        XCTAssertNil(validator.validatePassword("123456"))
    }
}
