# Phase 1: HeroAcademia Foundation

## Status: Complete

### Completed Steps

- [x] Step 1: Directory Structure & project.yml
- [x] Step 2: Data Models (4 files)
- [x] Step 3: Extensions
- [x] Step 4: FirebaseService
- [x] Step 5: ViewModels
- [x] Step 6: Views (MVP screens)
- [x] Step 7: watchOS Skeleton
- [x] Step 8: Resources
- [x] Step 9: Tests (4 files)
- [x] Step 10: Generate Xcode project

---

# Phase 2: Core Features

## Status: Complete

### Completed Steps

- [x] Step 1: GoalEngine (pure utility)
  - `GoalEngine.swift` — bmi(), streak(), projectedCompletionDate(), requiredDailyPace()
  - `GoalEngineTests.swift` — 11 tests covering all 4 methods

- [x] Step 2: Goal.swift + FirebaseService updates
  - Removed misleading `progressPercentage` computed var, added `daysRemaining`
  - Added `updateGoal()` and `deactivateGoal()` to protocol + implementation + mock

- [x] Step 3: HealthKitService
  - `HealthKitServiceProtocol` — 8 methods (auth, fetch, save)
  - `HealthKitService` — concrete class, gracefully no-ops on simulator
  - `MockHealthKitService.swift` — for testing

- [x] Step 4: project.yml update
  - HealthKit entitlement + Info.plist usage descriptions
  - `HeroAcademia.entitlements` with HealthKit capability
  - HealthKit.framework SDK dependency

- [x] Step 5: TestFixtures
  - Factory methods: measurement(), goal(), userProfile()
  - measurementHistory() for chart/trend test data

- [x] Step 6: GoalViewModel + Goal views
  - `GoalViewModel.swift` — @Observable @MainActor, goal CRUD
  - `GoalSettingView.swift` — form (type picker, target, deadline)
  - `GoalDetailView.swift` — progress bar, pace, projected date
  - `GoalViewModelTests.swift` — 5 tests

- [x] Step 7: SettingsView
  - Account section, HealthKit status, app version, sign out

- [x] Step 8: DashboardViewModel
  - Loads measurements (limit: 30), active goal, user profile
  - Computed: calculatedBMI, goalProgress, streak, projectedDate
  - `DashboardViewModelTests.swift` — 7 tests

- [x] Step 9: Dashboard components
  - `WeightTrendMiniChart.swift` — Swift Charts line chart
  - `GoalProgressCard.swift` — goal progress bar card

- [x] Step 10: DashboardView + MainTabView + RootView update
  - `DashboardView.swift` — latest stats, goal card, trend chart, streak
  - `MainTabView.swift` — 3 tabs: ダッシュボード / 計測記録 / 設定
  - `RootView.swift` — swapped to MainTabView, added HealthKitService

- [x] Step 11: MeasurementViewModel enhancement
  - Optional HealthKitServiceProtocol dependency
  - BMI calculation using GoalEngine.bmi + user profile height
  - HealthKit write-through on save
  - UI tests updated for TabView navigation

- [x] Step 12: Build, test, verify
  - `xcodegen generate` ✅
  - `xcodebuild build` ✅ BUILD SUCCEEDED
  - 47 unit tests across 7 suites ✅ ALL PASSED
  - UI tests updated for TabView (need Firebase to run)

### Test Results (47 tests, 7 suites)

| Suite | Tests | Status |
|-------|-------|--------|
| BodyMeasurement Tests | 4 | ✅ |
| DashboardViewModel Tests | 7 | ✅ |
| FirebaseService Mock Tests | 6 | ✅ |
| GoalEngine Tests | 11 | ✅ |
| Goal Tests | 7 | ✅ |
| GoalViewModel Tests | 5 | ✅ |
| MeasurementViewModel Tests | 7 | ✅ |

### New Files (17 production + 5 test = 22)

```
HeroAcademia/Core/Services/GoalEngine.swift
HeroAcademia/Core/Services/HealthKitService.swift
HeroAcademia/HeroAcademia.entitlements
HeroAcademia/Features/Dashboard/DashboardView.swift
HeroAcademia/Features/Dashboard/DashboardViewModel.swift
HeroAcademia/Features/Dashboard/Components/GoalProgressCard.swift
HeroAcademia/Features/Dashboard/Components/WeightTrendMiniChart.swift
HeroAcademia/Features/Goals/GoalSettingView.swift
HeroAcademia/Features/Goals/GoalDetailView.swift
HeroAcademia/Features/Goals/GoalViewModel.swift
HeroAcademia/Features/Settings/SettingsView.swift
HeroAcademia/Features/MainTabView.swift
HeroAcademiaTests/Services/GoalEngineTests.swift
HeroAcademiaTests/Services/MockHealthKitService.swift
HeroAcademiaTests/ViewModels/DashboardViewModelTests.swift
HeroAcademiaTests/ViewModels/GoalViewModelTests.swift
HeroAcademiaTests/Helpers/TestFixtures.swift
```

### Modified Files (6)

```
HeroAcademia/Core/Models/Goal.swift — removed broken progressPercentage, added daysRemaining
HeroAcademia/Core/Services/FirebaseService.swift — added updateGoal/deactivateGoal
HeroAcademia/RootView.swift — MainTabView + HealthKitService
HeroAcademia/Features/Measurement/MeasurementViewModel.swift — HealthKit + BMI
HeroAcademiaTests/Services/FirebaseServiceTests.swift — MockFirebaseService updated
HeroAcademiaUITests/AuthFlowUITests.swift — TabView navigation
project.yml — HealthKit entitlement + framework
```
