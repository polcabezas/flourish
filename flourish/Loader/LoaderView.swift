import SwiftUI

// MARK: - Loader State

@MainActor
final class LoaderState: ObservableObject {
    enum Phase { case loading, success }
    @Published var phase: Phase = .loading
    @Published var successMessage: String = "Copied to clipboard"
    /// Always kept in sync with the panel's frame width so SwiftUI reports a
    /// stable preferred content size and NSHostingView never resizes the window.
    @Published var width: CGFloat = FS.loaderWidth
}

// MARK: - Loader View
// Loading: forest-green spinner inside a pill.
// Success: checkmark + "Copied to clipboard" label inside the same pill.

struct LoaderView: View {
    @ObservedObject var state: LoaderState

    var body: some View {
        Group {
            if state.phase == .success {
                HStack(spacing: FS.xs) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color.flourishAccent)
                    Text(state.successMessage)
                        .font(.flourishMeta)
                        .foregroundColor(.flourishAccent)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.92)))
            } else {
                SpinnerView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: state.phase == .success)
        .padding(.horizontal, FS.lg)
        .padding(.vertical, FS.sm)
        // Both dimensions must be fixed so NSHostingView.updateAnimatedWindowSize
        // always sees the same preferred size as the panel frame and never loops.
        .frame(width: state.width, height: FS.loaderHeight)
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

// MARK: - Spinner

private struct SpinnerView: View {
    var body: some View {
        ProgressView()
            .scaleEffect(0.45)
            .frame(width: 16, height: 16)
            .tint(Color.flourishAccent)
    }
}

#Preview {
    LoaderView(state: LoaderState())
        .frame(width: 200, height: 80)
        .background(Color.gray.opacity(0.2))
}
