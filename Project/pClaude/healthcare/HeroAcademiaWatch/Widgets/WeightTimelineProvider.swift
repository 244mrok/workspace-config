import WidgetKit

struct WeightEntry: TimelineEntry {
    let date: Date
    let weight: String
    let bodyFat: String
    let goalProgress: Double
    let streak: Int
}

struct WeightTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeightEntry {
        WeightEntry(
            date: Date(),
            weight: "70.0",
            bodyFat: "20.0",
            goalProgress: 0.5,
            streak: 7
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WeightEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeightEntry>) -> Void) {
        let entry = makeEntry()
        // Refresh every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func makeEntry() -> WeightEntry {
        let data = WatchData.loadFromCache()
        return WeightEntry(
            date: Date(),
            weight: data?.latestWeight.map { String(format: "%.1f", $0) } ?? "--.-",
            bodyFat: data?.latestBodyFat.map { String(format: "%.1f", $0) } ?? "--.-",
            goalProgress: (data?.goalProgress ?? 0) / 100,
            streak: data?.streak ?? 0
        )
    }
}
