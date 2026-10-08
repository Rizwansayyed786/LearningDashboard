# Learning Dashboard (iOS)

SwiftUI app: Login → Course Dashboard → Course Details, with lesson completion and offline support.
Swift concurrency, `@Observable`, `URLSession`, UserDefaults JSON cache. No third-party dependencies. iOS 17+.

**Run:** `brew install xcodegen && xcodegen generate && open LearningDashboard.xcodeproj` (or see "Manual setup" below), then Cmd+R. Tests: Cmd+U.
**Demo login:** `student@example.com` / `password123` (anything else shows the error state).
**Demo offline (simulator):** dashboard toolbar → bug icon → "Simulate offline", then pull to refresh. Turning off Mac Wi-Fi works too, because the mock API consults `NWPathMonitor`.

## 1. Architecture
MVVM + lightweight Clean Architecture. Dependencies point inward: `View → ViewModel → UseCase → Repository protocol ← Repository impl → Remote / Local data sources`.
- **Domain** (Foundation only): entities, `ProgressCalculator`, `LoginValidator`, repository protocols, use cases.
- **Data**: Codable DTOs (`CourseModel`) mapped to domain entities, `CourseAPI`/`AuthAPI` (mock + URLSession-based), `CourseLocalDataSource`, repository implementations.
- **Features**: per screen, a View, a `@MainActor @Observable` ViewModel and a state enum (`idle/loading/loaded/empty/error`), so impossible states can't be represented.
- **DI**: `AppContainer` builds everything with constructor injection; no framework. ViewModels and repositories are tested with stubs/fakes.
- Progress is **derived** from lessons (`Course.progress`), never stored, so it can't go stale.

## 2. Offline Support
`CourseRepositoryImpl.getCourses()` calls the remote API first; on success it merges in locally completed lessons and writes the result to the cache as JSON. On failure it returns the cached courses (flagged `isFromCache`, shown as an "Offline" banner); with no cache it throws `noCachedData`, which the dashboard shows as an error state. Completing a lesson updates the cache and returns the updated `Course`. The repository is an `actor` so cache read-modify-write can't race.

## 3. Security
Authentication tokens would be stored in the iOS Keychain in a production app. UserDefaults must not hold credentials. The mock login returns no token. Production would also add HTTPS with ATS, certificate pinning where warranted, and token refresh.

## 4. Scale: 1M users / hundreds of courses
1. Pagination / incremental loading (cursor-based) instead of fetching all courses.
2. Backend and CDN caching with ETag / `If-None-Match` to avoid re-downloading unchanged data.
3. Database-backed local persistence (SwiftData/Core Data/SQLite) with indexed queries, replacing the UserDefaults blob. The `LocalStorage` / `CourseLocalDataSource` seam makes this a swap.
4. Server-synced progress with idempotent writes and conflict handling, plus token refresh and secure networking.
5. Observability: crash reporting, analytics, API monitoring, feature flags and staged rollouts.

## 5. Android implementation
```
Jetpack Compose → ViewModel (StateFlow) → Use Cases → Repository → Remote (Retrofit/OkHttp) + Local (Room)
```
Kotlin, Compose, ViewModel, Coroutines/Flow, Retrofit/OkHttp, Room for courses and lessons, DataStore for preferences, EncryptedSharedPreferences/Keystore for tokens, Hilt (or manual DI). Same sealed-state-per-screen approach.

## Design decisions
- **UserDefaults over SwiftData:** tiny dataset, simple requirement; behind an abstraction so it's replaceable.
- **Domain not `Codable`:** DTOs own the wire/cache format.
- **Integer progress math:** `Int(Double(29)/100*100)` gives 28 due to floating-point error; integer arithmetic avoids that.
- **Local progress wins on refresh:** a remote reload never un-completes a lesson.

## Manual setup (without XcodeGen)
New iOS App project "LearningDashboard" (SwiftUI, iOS 17+), delete the template files, drag in the `LearningDashboard/` folder (including `Resources/courses.json`, with "Copy items" and the app target checked), add a Unit Testing Bundle target and add `Tests/LearningDashboardTests/*`. Set Swift Language Version to 5 and, on Xcode 26, Default Actor Isolation to `nonisolated`.
