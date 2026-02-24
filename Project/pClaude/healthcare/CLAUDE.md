# CLAUDE.md — HeroAcademia

iOS健康管理アプリ。体重・体脂肪率を中心としたボディコンポジション管理で、目標期間内の減量・体脂肪率コントロールを支援する。

## Project Overview

| Item | Value |
|------|-------|
| App Name | HeroAcademia |
| Platform | iOS (SwiftUI) + watchOS (companion) |
| Language | Swift 5.9+ / iOS 17+ / watchOS 10+ |
| Backend | Firebase (Auth, Firestore, Cloud Functions) |
| UI Language | Japanese only |
| Monetization | Free (personal use) |

## Architecture

```
HeroAcademia/
├── App/
│   ├── HeroAcademiaApp.swift          # App entry point
│   └── AppDelegate.swift              # Firebase setup, push notifications
├── Core/
│   ├── Models/                        # Data models (Codable + Firestore)
│   │   ├── UserProfile.swift
│   │   ├── BodyMeasurement.swift      # Weight, body fat%, BMI, muscle mass, visceral fat, metabolic age
│   │   ├── Goal.swift                 # Target weight/fat% + deadline
│   │   └── HealthDevice.swift         # Connected device metadata
│   ├── Services/
│   │   ├── HealthKitService.swift     # Apple HealthKit read/write
│   │   ├── FirebaseService.swift      # Firestore CRUD, Auth
│   │   ├── OmronService.swift         # Omron Connect SDK integration
│   │   ├── DeviceSyncService.swift    # Third-party device sync (Fitbit/Garmin/Withings)
│   │   ├── NotificationService.swift  # Local + push notification scheduling
│   │   └── GoalEngine.swift           # Progress calculation, projected completion
│   └── Extensions/
│       ├── Date+Extensions.swift
│       └── Double+Formatting.swift
├── Features/
│   ├── Dashboard/
│   │   ├── DashboardView.swift        # Main screen: today's stats, goal progress, trends
│   │   ├── DashboardViewModel.swift
│   │   └── Components/
│   │       ├── BodyCompositionCard.swift
│   │       ├── GoalProgressBar.swift
│   │       ├── TrendMiniChart.swift
│   │       └── StreakBadge.swift
│   ├── Measurement/
│   │   ├── MeasurementInputView.swift # Manual entry form
│   │   ├── MeasurementHistoryView.swift
│   │   └── MeasurementViewModel.swift
│   ├── Analytics/
│   │   ├── AnalyticsView.swift        # Rich dashboard with charts
│   │   ├── AnalyticsViewModel.swift
│   │   └── Charts/
│   │       ├── WeightTrendChart.swift
│   │       ├── BodyFatTrendChart.swift
│   │       ├── CorrelationChart.swift # Sleep vs weight, exercise vs fat%
│   │       ├── CompositionBreakdown.swift
│   │       └── HeatmapView.swift      # Weekly/monthly activity heatmap
│   ├── Goals/
│   │   ├── GoalSettingView.swift      # Set target + deadline
│   │   ├── GoalDetailView.swift       # Progress, projected date, daily pace
│   │   └── GoalViewModel.swift
│   ├── Devices/
│   │   ├── DeviceListView.swift       # Connected devices management
│   │   ├── DevicePairingView.swift    # Add Omron/Fitbit/Garmin/Withings
│   │   └── DeviceViewModel.swift
│   ├── Settings/
│   │   ├── SettingsView.swift
│   │   └── NotificationSettingsView.swift
│   └── Onboarding/
│       ├── OnboardingView.swift       # Initial setup flow
│       └── HealthKitPermissionView.swift
├── WatchApp/
│   ├── HeroAcademiaWatchApp.swift     # watchOS entry point
│   ├── WatchDashboardView.swift       # Today's weight, goal progress
│   ├── QuickLogView.swift             # Quick weigh-in from wrist
│   └── ComplicationProvider.swift     # Watch face complications
├── Resources/
│   ├── Assets.xcassets
│   ├── Localizable.strings            # Japanese strings
│   └── GoogleService-Info.plist       # Firebase config
└── Tests/
    ├── GoalEngineTests.swift
    ├── HealthKitServiceTests.swift
    └── ViewModelTests/
```

## Data Models

### BodyMeasurement
```swift
struct BodyMeasurement: Codable, Identifiable {
    let id: String
    let date: Date
    let weight: Double?            // kg
    let bodyFatPercentage: Double?  // %
    let bmi: Double?
    let muscleMass: Double?         // kg
    let visceralFatLevel: Int?      // 1-59 (Omron scale)
    let metabolicAge: Int?          // years
    let source: MeasurementSource   // .healthKit, .omron, .manual, .fitbit, .garmin, .withings
    let deviceId: String?
}
```

### Goal
```swift
struct Goal: Codable, Identifiable {
    let id: String
    let type: GoalType              // .weight, .bodyFat
    let targetValue: Double         // Target weight(kg) or body fat(%)
    let startValue: Double          // Starting value
    let startDate: Date
    let deadline: Date
    let isActive: Bool
}
```

## Data Sources & Integration

### Apple HealthKit (Primary)
- **Read**: 体重, 体脂肪率, BMI, 歩数, 心拍数, 睡眠, ワークアウト
- **Write**: 手動入力データをHealthKitにも反映
- バックグラウンドデリバリーで自動同期

### Omron Connect
- Omron Connect SDK経由で体重計・体組成計から直接取得
- 対応機種: HBF-256T, HBF-702T等のBluetooth対応モデル
- 体重, 体脂肪率, 骨格筋率, 内臓脂肪レベル, 体年齢

### Third-Party Devices
- **Fitbit**: Fitbit Web API (OAuth 2.0) → 体重, 体脂肪率, 歩数
- **Garmin**: Garmin Connect API → 体重, 体組成
- **Withings**: Withings API (OAuth 2.0) → 体重, 体脂肪率, 筋肉量

### Manual Entry
- 食事記録 (カロリー, PFCバランス)
- 水分摂取量
- サプリメント
- 体調メモ

## Goal System

シンプルな目標＋期限方式:
1. 目標値（体重 or 体脂肪率）と達成期限を設定
2. 日次の必要ペースを自動計算（例: 1日あたり-0.05kg）
3. 実績に基づく達成予測日を常時表示
4. 進捗率をプログレスバーで可視化

## Analytics & Visualization

### Rich Dashboard
- **トレンドチャート**: 体重・体脂肪率の推移（Swift Charts）
- **相関分析**: 睡眠時間 vs 体重変動、運動量 vs 体脂肪率
- **ヒートマップ**: 週間・月間の測定頻度・活動量
- **体組成ブレイクダウン**: 筋肉量・脂肪量・水分量の円グラフ
- **ストリーク**: 連続測定日数の表示とバッジ

### Chart Library
- Swift Charts (iOS 16+) をメインで使用
- カスタムチャートが必要な場合のみサードパーティ検討

## Notifications

### Smart Reminders
- **計測リマインダー**: 毎朝の体重測定リマインド（時刻カスタマイズ可）
- **マイルストーン通知**: 目標の25%, 50%, 75%達成時にお祝い通知
- **ストリーク通知**: 連続記録の継続・途切れ警告
- **週次レポート**: 毎週日曜に1週間のサマリー通知

## Apple Watch Companion

- **Today表示**: 今日の体重、目標までの残り、進捗率
- **Quick Log**: 手首から素早く体重入力
- **Complication**: ウォッチフェイスに体重・進捗を表示
- iPhone ↔ Watch間はWatchConnectivityで同期

## Firebase Structure

```
users/
  {userId}/
    profile: { name, height, birthday, gender }
    goals/
      {goalId}: { type, targetValue, startValue, startDate, deadline, isActive }
    measurements/
      {measurementId}: { date, weight, bodyFat, bmi, muscleMass, ... }
    devices/
      {deviceId}: { type, name, lastSyncDate }
    settings/
      notifications: { weighInTime, weeklyReport, milestones, streaks }
```

## Build & Run Commands

```bash
# Xcode project
open HeroAcademia.xcodeproj

# Swift Package Manager dependencies
swift package resolve

# Build (command line)
xcodebuild -scheme HeroAcademia -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run tests
xcodebuild -scheme HeroAcademia -destination 'platform=iOS Simulator,name=iPhone 16' test

# Watch app
xcodebuild -scheme HeroAcademiaWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)' build
```

## Dependencies (Swift Package Manager)

| Package | Purpose |
|---------|---------|
| firebase-ios-sdk | Auth, Firestore, Cloud Messaging |
| OmronConnectSDK | Omron体組成計連携 |
| swift-algorithms | コレクション操作ユーティリティ |

## Development Guidelines

### SwiftUI Patterns
- MVVM architecture: View → ViewModel → Service
- `@Observable` macro (iOS 17+) for ViewModels
- `@Environment` for dependency injection of services
- Swift Concurrency (async/await) for all非同期処理

### Data Flow
1. デバイス/HealthKit → Service層でデータ取得
2. Service → Firestore に保存（オフライン対応はFirestore SDKが処理）
3. ViewModel → Firestoreリスナーでリアルタイム更新
4. View → ViewModelの@Publishedプロパティをバインド

### Code Style
- SwiftLint適用
- 日本語コメント可（UIテキストは全て日本語）
- Preview用のモックデータを各Viewに用意

### Testing
- ViewModelのユニットテスト必須
- GoalEngineのロジックテスト必須
- HealthKitServiceはプロトコルでモック化
- UI TestはメインフローのみSwift Testing

## MVP Milestones

### Phase 1: Foundation
- [ ] Xcodeプロジェクトセットアップ（iOS + watchOS targets）
- [ ] Firebase初期設定（Auth, Firestore）
- [ ] データモデル定義
- [ ] 基本CRUD（測定データの記録・取得）

### Phase 2: Core Features
- [ ] HealthKit連携（体重・体脂肪率の読み書き）
- [ ] 手動入力フォーム
- [ ] ダッシュボード画面
- [ ] 目標設定・進捗表示

### Phase 3: Analytics & Devices
- [ ] Swift Chartsでトレンドチャート
- [ ] 相関分析・ヒートマップ
- [ ] Omron Connect連携
- [ ] Fitbit/Garmin/Withings API連携

### Phase 4: Watch & Polish
- [ ] Apple Watch companion app
- [ ] Smart notifications
- [ ] ストリーク・バッジシステム
- [ ] UIブラッシュアップ・アニメーション

## Future Enhancements (Post-MVP)
- AI coaching (Claude API連携で食事・運動アドバイス)
- 食事写真からのカロリー推定
- ソーシャル機能（友達と進捗共有）
- ウィジェット（ホーム画面に体重・進捗表示）
- Siri Shortcuts対応
- PDF/CSVエクスポート


## Workflow Orchestration

### 1. Plan Node Default
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately - don't keep pushing
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

### 2. Subagent Strategy
- Use subagents liberally to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One tack per subagent for focused execution

### 3. Self-Improvement Loop
- After ANY correction from the user: update `tasks/lessons.md` with the pattern
- Write rules for yourself that prevent the same mistake
- Ruthlessly iterate on these lessons until mistake rate drops
- Review lessons at session start for relevant project

### 4. Verification Before Done
- Never mark a task complete without proving it works
- Diff behavior between main and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness

### 5. Demand Elegance (Balanced)
- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes - don't over-engineer
- Challenge your own work before presenting it

### 6. Autonomous Bug Fixing
- When given a bug report: just fix it. Don't ask for hand-holding
- Point at logs, errors, failing tests - then resolve them
- Zero context switching required from the user
- Go fix failing CI tests without being told how

## Task Management

1. **Plan First**: Write plan to `tasks/todo.md` with checkable items
2. **Verify Plan**: Check in before starting implementation
3. **Track Progress**: Mark items complete as you go
4. **Explain Changes**: High-level summary at each step
5. **Document Results**: Add review section to `tasks/todo.md`
6. **Capture Lessons**: Update `tasks/lessons.md` after corrections

## Core Principles

- **Simplicity First**: Make every change as simple as possible. Impact minimal code.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimat Impact**: Changes should only touch what's necessary. Avoid introducing bugs.