import SwiftUI

// MARK: - View Model

@MainActor
final class LimitReachedViewModel: ObservableObject {
    static let shared = LimitReachedViewModel()
    static let totalTime: Double = 12.0

    @Published var timeRemaining: Double = LimitReachedViewModel.totalTime

    private init() {}

    func reset() {
        timeRemaining = Self.totalTime
    }
}

// MARK: - Popup View

struct LimitReachedPopupView: View {
    @ObservedObject private var vm = LimitReachedViewModel.shared
    private let ticker = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 0) {
            leftContent
            rightPanel
        }
        .frame(width: 400, height: 170)
        .background(Color.flourishSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onReceive(ticker) { _ in
            guard vm.timeRemaining > 0 else { return }
            vm.timeRemaining -= 0.05
            if vm.timeRemaining <= 0 {
                vm.timeRemaining = 0
                LimitReachedWindowController.shared.dismiss()
            }
        }
    }

    // MARK: - Left Column

    @State private var upgradeHovered = false

    private var leftContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("You hit your monthly\nimprovement limit.")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.flourishTextPrimary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            Text("Upgrade to get more improvements\nand continue using flourish!")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.flourishTextSecondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Button(action: {
                LimitReachedWindowController.shared.dismiss()
                MainWindowController.shared.showAndFocus(section: .account)
            }) {
                Text("Upgrade")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .background(upgradeHovered ? Color(hex: "#4A6840") : .flourishButtonBg)
                    .cornerRadius(FS.radiusSm)
            }
            .buttonStyle(.plain)
            .onHover { inside in
                upgradeHovered = inside
                if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Right Panel

    private var rightPanel: some View {
        ZStack(alignment: .topTrailing) {
            Color(hex: "#C8DFC0")

            flourishWordmarkView(height: 34, color: Color(hex: "#3D6135"))
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            timerCloseButton
                .padding(10)
        }
        .frame(width: 140)
    }

    // MARK: - Timer Close Button

    private var timerCloseButton: some View {
        ZStack {
            // Track ring
            Circle()
                .stroke(Color.black.opacity(0.12), lineWidth: 2)
                .frame(width: 26, height: 26)

            // Draining progress arc
            Circle()
                .trim(from: 0, to: max(0, CGFloat(vm.timeRemaining / LimitReachedViewModel.totalTime)))
                .stroke(
                    Color.black.opacity(0.28),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 26, height: 26)
                .animation(.linear(duration: 0.05), value: vm.timeRemaining)

            // X button
            Button(action: {
                LimitReachedWindowController.shared.dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(Color.black.opacity(0.6))
                    .frame(width: 22, height: 22)
                    .background(Color.white.opacity(0.7))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .pointerCursor()
        }
    }
}
