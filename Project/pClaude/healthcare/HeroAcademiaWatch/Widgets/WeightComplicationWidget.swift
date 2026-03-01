import SwiftUI
import WidgetKit

struct WeightComplicationWidget: Widget {
    let kind = "com.heroacademia.weight"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: WeightTimelineProvider()
        ) { entry in
            WeightComplicationEntryView(entry: entry)
        }
        .configurationDisplayName("体重")
        .description("最新の体重と目標進捗を表示します")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

struct WeightComplicationEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: WeightEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            WeightCircularView(entry: entry)
        case .accessoryRectangular:
            WeightRectangularView(entry: entry)
        case .accessoryInline:
            WeightInlineView(entry: entry)
        default:
            WeightCircularView(entry: entry)
        }
    }
}
