# Phase 1: HeroAcademia Foundation

## Status: Complete (pending Xcode build verification)

### Completed Steps

- [x] Step 1: Directory Structure & project.yml
  - Created all directories (HeroAcademia/, HeroAcademiaWatch/, HeroAcademiaTests/)
  - Created `project.yml` (iOS 17+, watchOS 10+, SPM: firebase-ios-sdk 11.6.0)
  - Created `.swiftlint.yml`

- [x] Step 2: Data Models (4 files)
  - `MeasurementSource.swift` — enum with 6 sources + 日本語 displayName
  - `BodyMeasurement.swift` — full body composition model with @DocumentID
  - `UserProfile.swift` — user profile with Gender enum
  - `Goal.swift` — goal with progress calculation logic

- [x] Step 3: Extensions
  - `Date+Extensions.swift` — 日本語フォーマット (shortDate, medium, relative)
  - `Double+Formatting.swift` — weight/bodyFat/BMI formatting

- [x] Step 4: FirebaseService
  - `FirebaseServiceProtocol` — full protocol for testing
  - `FirebaseService` — @Observable class with Auth + Firestore CRUD
  - Real-time listener support (listenToMeasurements)

- [x] Step 5: ViewModels
  - `AuthViewModel` — email/password auth with form validation
  - `MeasurementViewModel` — CRUD + real-time listener + form management

- [x] Step 6: Views (MVP screens)
  - `HeroAcademiaApp.swift` + `AppDelegate.swift` (Firebase init)
  - `RootView.swift` — auth state routing
  - `AuthView.swift` — login/signup form (日本語 UI)
  - `MeasurementListView.swift` — measurement list + swipe delete
  - `MeasurementInputView.swift` — measurement input form

- [x] Step 7: watchOS Skeleton
  - `HeroAcademiaWatchApp.swift` + `ContentView.swift` (placeholder)

- [x] Step 8: Resources
  - `Assets.xcassets/Contents.json`
  - `Localizable.strings` (Japanese)

- [x] Step 9: Tests (4 files)
  - `BodyMeasurementTests.swift` — creation, JSON roundtrip, source display names
  - `GoalTests.swift` — display names, total change, daily pace, progress %
  - `FirebaseServiceTests.swift` — MockFirebaseService + CRUD tests
  - `MeasurementViewModelTests.swift` — ViewModel state, load, add, delete, error handling

- [x] Step 10: Generate Xcode project
  - `xcodegen generate` ✅ 成功
  - `xcodebuild build` ⚠️ Xcode.app 未インストールのため実行不可

## Remaining User Actions

1. **Install Xcode.app** from Mac App Store
2. After Xcode installed: `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`
3. Open `HeroAcademia.xcodeproj` or run: `xcodebuild -scheme HeroAcademia -destination 'platform=iOS Simulator,name=iPhone 16' build`
4. **Firebase setup**:
   - Create project at https://console.firebase.google.com
   - Add iOS app (Bundle ID: `com.heroacademia.app`)
   - Download `GoogleService-Info.plist` → `HeroAcademia/Resources/`
   - Enable Email/Password auth
   - Create Firestore database

## File Count: 25 files created
