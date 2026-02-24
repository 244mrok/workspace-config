import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "scalemass")
                .font(.largeTitle)
                .foregroundStyle(.blue)

            Text("HeroAcademia")
                .font(.headline)

            Text("準備中...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ContentView()
}
