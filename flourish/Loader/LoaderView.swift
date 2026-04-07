import SwiftUI

// MARK: - Loader View
// Three forest-green dots with staggered pulse animation inside a pill.

struct LoaderView: View {
    var body: some View {
        HStack(spacing: FS.loaderDotSpacing) {
            PulsingDot(delay: 0.00)
            PulsingDot(delay: 0.18)
            PulsingDot(delay: 0.36)
        }
        .padding(.horizontal, FS.lg)
        .padding(.vertical, FS.sm)
        .frame(width: FS.loaderWidth, height: FS.loaderHeight)
        .background(
            Capsule()
                .fill(Color.flourishSurface)
                .shadow(
                    color: .black.opacity(FS.loaderShadowOpacity),
                    radius: FS.loaderShadowRadius,
                    x: 0, y: FS.loaderShadowY
                )
        )
    }
}

// MARK: - Pulsing Dot

private struct PulsingDot: View {
    let delay: Double
    @State private var opacity: Double = 0.25

    var body: some View {
        Circle()
            .fill(Color.flourishAccent)
            .frame(width: FS.loaderDotSize, height: FS.loaderDotSize)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 0.55)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    opacity = 1.0
                }
            }
    }
}

#Preview {
    LoaderView()
        .frame(width: 200, height: 80)
        .background(Color.gray.opacity(0.2))
}
