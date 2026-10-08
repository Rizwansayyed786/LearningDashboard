import Foundation

/// Composition root: the only place that knows concrete types.
/// Constructor injection throughout, no DI framework.
@MainActor
final class AppContainer {
    let connectivity: ConnectivityMonitor

    private let authRepository: AuthRepository
    private let courseRepository: CourseRepository

    init(
        connectivity: ConnectivityMonitor = ConnectivityMonitor(),
        storage: LocalStorage = UserDefaultsStorage(),
        bundle: Bundle = .main
    ) {
        self.connectivity = connectivity

        // To use a real backend, swap MockCourseAPI for:
        // RemoteCourseAPI(client: URLSessionNetworkClient(baseURL: <your API URL>))
        let courseAPI: CourseAPI = MockCourseAPI(connectivity: connectivity, bundle: bundle)
        let localDataSource: CourseLocalDataSource = UserDefaultsCourseLocalDataSource(storage: storage)

        self.courseRepository = CourseRepositoryImpl(remote: courseAPI, local: localDataSource)
        self.authRepository = AuthRepositoryImpl(api: MockAuthAPI())
    }

    func makeLoginViewModel() -> LoginViewModel {
        LoginViewModel(loginUseCase: LoginUseCase(repository: authRepository))
    }

    func makeDashboardViewModel() -> DashboardViewModel {
        DashboardViewModel(getCoursesUseCase: GetCoursesUseCase(repository: courseRepository))
    }

    func makeCourseDetailsViewModel(
        courseId: Int,
        onCourseUpdated: @escaping (Course) -> Void
    ) -> CourseDetailsViewModel {
        CourseDetailsViewModel(
            courseId: courseId,
            getCourseDetailsUseCase: GetCourseDetailsUseCase(repository: courseRepository),
            completeLessonUseCase: CompleteLessonUseCase(repository: courseRepository),
            onCourseUpdated: onCourseUpdated
        )
    }
}
