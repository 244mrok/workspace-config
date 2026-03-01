import SwiftUI

/// Celebration overlay with expanding rings and checkmark for goal completion.
struct CelebrationView: View {
    @State private var isAnimating = false
    @State private var showCheck = false

    var body: some View {
        ZStack {
            // Expanding rings
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(
                        Color.green.opacity(isAnimating ? 0 : 0.6),
                        lineWidth: 2
                    )
                    .scaleEffect(isAnimating ? 2.5 + CGFloat(index) * 0.5 : 0.5)
                    .animation(
                        .easeOut(duration: 1.2)
                            .delay(Double(index) * 0.2),
                        value: isAnimating
                    )
            }

            // Checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)
                .scaleEffect(showCheck ? 1.0 : 0.0)
                .opacity(showCheck ? 1.0 : 0.0)
                .animation(.spring(duration: 0.5, bounce: 0.4).delay(0.3), value: showCheck)
        }
        .frame(width: 200, height: 200)
        .onAppear {
            isAnimating = true
            showCheck = true
        }
    }
}
