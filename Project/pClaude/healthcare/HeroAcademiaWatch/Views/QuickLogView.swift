import SwiftUI

struct QuickLogView: View {
    let sessionService: WatchSessionService
    @Environment(\.dismiss) private var dismiss

    @State private var weight: Double
    @State private var showSuccess = false

    init(sessionService: WatchSessionService) {
        self.sessionService = sessionService
        // Start from latest weight or sensible default
        _weight = State(initialValue: sessionService.watchData?.latestWeight ?? 65.0)
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("体重を記録")
                .font(.headline)

            Text(String(format: "%.1f", weight))
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .focusable()
                .digitalCrownRotation(
                    $weight,
                    from: 30.0,
                    through: 200.0,
                    by: 0.1,
                    sensitivity: .medium
                )

            Text("kg")
                .font(.caption)
                .foregroundStyle(.secondary)

            if showSuccess {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.green)
                    .transition(.scale.combined(with: .opacity))
            } else {
                Button("保存") {
                    sessionService.sendWeightLog(weight: weight)
                    withAnimation {
                        showSuccess = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
        }
        .padding()
    }
}
