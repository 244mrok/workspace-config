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

---

# Phase 3: Analytics & Devices

## Status: Complete

### Completed Steps

- [x] Step 1: Extend HealthKitService for correlation data
  - Added `fetchBodyFatHistory(days:)`, `fetchStepCounts(days:)`, `fetchSleepAnalysis(days:)` to protocol + implementation
  - Updated `requestAuthorization()` readTypes: added `.stepCount`, `.sleepAnalysis`
  - Updated MockHealthKitService with mock properties + method implementations

- [x] Step 2: HealthDevice model + device service protocols
  - `HealthDevice.swift` — DeviceType enum (omron/fitbit/garmin/withings) + HealthDevice struct
  - `DeviceSyncService.swift` — protocol + StubDeviceSyncService (all throw notAvailable)
  - `OmronService.swift` — protocol + StubOmronService (throws sdkNotAvailable)
  - Added device CRUD to FirebaseServiceProtocol + FirebaseService + MockFirebaseService

- [x] Step 3: TestFixtures extension
  - Added `device()` factory for HealthDevice
  - Added `measurementWithComposition()` factory with muscleMass/visceralFat/metabolicAge

- [x] Step 4: AnalyticsViewModel
  - @Observable @MainActor with measurements, stepData, sleepData, selectedPeriod
  - Computed: weightTrendData, bodyFatTrendData, sleepWeightCorrelation, stepsBodyFatCorrelation, compositionBreakdown, heatmapData
  - Supporting types: AnalyticsPeriod, CorrelationPoint, CompositionData, HeatmapEntry

- [x] Step 5: Analytics chart views (5 charts)
  - `WeightTrendChart.swift` — full-size with optional goalWeight RuleMark
  - `BodyFatTrendChart.swift` — orange scheme with optional goalBodyFat RuleMark
  - `CorrelationChart.swift` — scatter plot with two modes (sleepWeight / stepsBodyFat)
  - `CompositionBreakdown.swift` — SectorMark donut chart with legend
  - `HeatmapView.swift` — LazyVGrid 7-column calendar with intensity coloring

- [x] Step 6: AnalyticsView + MainTabView integration
  - `AnalyticsView.swift` — period selector, ScrollView with all 5 charts
  - MainTabView updated: 4 tabs (ダッシュボード / 計測記録 / 分析 / 設定)

- [x] Step 7: Device management UI
  - `DeviceViewModel.swift` — @Observable @MainActor with load/connect/disconnect/sync
  - `DeviceListView.swift` — connected devices + available types with "近日対応" badges
  - `DevicePairingView.swift` — "Coming soon" modal
  - SettingsView updated with "デバイス連携" NavigationLink

- [x] Step 8: Build, test, verify
  - `xcodegen generate` ✅
  - `xcodebuild build` ✅ BUILD SUCCEEDED
  - 86 unit tests across 11 suites ✅ ALL PASSED
  - 2 UI tests ✅ PASSED

### Test Results (86 unit tests, 11 suites)

| Suite | Tests | Status |
|-------|-------|--------|
| AnalyticsViewModel Tests | 15 | ✅ |
| BodyMeasurement Tests | 4 | ✅ |
| DashboardViewModel Tests | 7 | ✅ |
| DeviceSyncService Tests | 10 | ✅ |
| DeviceViewModel Tests | 8 | ✅ |
| FirebaseService Mock Tests | 6 | ✅ |
| GoalEngine Tests | 11 | ✅ |
| Goal Tests | 7 | ✅ |
| GoalViewModel Tests | 5 | ✅ |
| HealthDevice Model Tests | 7 | ✅ |
| MeasurementViewModel Tests | 7 | ✅ |

### New Files (17 production + 4 test = 21)

```
HeroAcademia/Core/Models/HealthDevice.swift
HeroAcademia/Core/Services/DeviceSyncService.swift
HeroAcademia/Core/Services/OmronService.swift
HeroAcademia/Features/Analytics/AnalyticsView.swift
HeroAcademia/Features/Analytics/AnalyticsViewModel.swift
HeroAcademia/Features/Analytics/Charts/WeightTrendChart.swift
HeroAcademia/Features/Analytics/Charts/BodyFatTrendChart.swift
HeroAcademia/Features/Analytics/Charts/CorrelationChart.swift
HeroAcademia/Features/Analytics/Charts/CompositionBreakdown.swift
HeroAcademia/Features/Analytics/Charts/HeatmapView.swift
HeroAcademia/Features/Devices/DeviceViewModel.swift
HeroAcademia/Features/Devices/DeviceListView.swift
HeroAcademia/Features/Devices/DevicePairingView.swift
HeroAcademiaTests/Models/HealthDeviceTests.swift
HeroAcademiaTests/Services/DeviceSyncServiceTests.swift
HeroAcademiaTests/ViewModels/AnalyticsViewModelTests.swift
HeroAcademiaTests/ViewModels/DeviceViewModelTests.swift
```

### Modified Files (7)

```
HeroAcademia/Core/Services/HealthKitService.swift — added fetchBodyFatHistory/fetchStepCounts/fetchSleepAnalysis + readTypes
HeroAcademia/Core/Services/FirebaseService.swift — added device CRUD (protocol + implementation)
HeroAcademia/Features/MainTabView.swift — added 分析 tab (4 tabs total)
HeroAcademia/Features/Settings/SettingsView.swift — added デバイス連携 section
HeroAcademiaTests/Services/MockHealthKitService.swift — added mock properties + methods for new protocol methods
HeroAcademiaTests/Services/FirebaseServiceTests.swift — MockFirebaseService updated with device methods
HeroAcademiaTests/Helpers/TestFixtures.swift — added device() + measurementWithComposition() factories
```
