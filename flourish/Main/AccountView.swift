import SwiftUI
import Defaults

// MARK: - Account View
// Only shown when authenticated. Sign-in lives in SignInView / SignInWindowController.

struct AccountView: View {
    @ObservedObject private var auth = AuthService.shared
    @StateObject private var vm = AccountViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Account")
                    .font(.flourishTitle)
                    .foregroundColor(.flourishTextPrimary)
                Spacer()
            }
            .padding(.horizontal, FS.xxl)
            .padding(.top, FS.xxl)
            .padding(.bottom, FS.lg)

            Rectangle()
                .fill(Color.flourishBorder)
                .frame(height: FS.borderWidth)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    AccountInfoSection(auth: auth, vm: vm)
                    AccountSectionDivider()
                    BillingSection(vm: vm)
                    Spacer(minLength: FS.xxl)
                }
            }
            .scrollIndicators(.hidden)
        }
        .background(Color.flourishSurface)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .task { await vm.loadUsage() }
    }
}

// MARK: - Account Info Section

private struct AccountInfoSection: View {
    @ObservedObject var auth: AuthService
    @ObservedObject var vm: AccountViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: FS.md) {
            AccountLabel("Account")

            HStack(spacing: FS.sm) {
                Text(auth.currentUser?.email ?? "")
                    .font(.flourishBody)
                    .foregroundColor(.flourishTextPrimary)
                Spacer()
                PlanBadge(plan: vm.usage?.plan ?? Defaults[.lastKnownSubscription])
            }

            if vm.isLoadingUsage {
                ProgressView().scaleEffect(0.7)
            } else if let u = vm.usage {
                VStack(alignment: .leading, spacing: FS.xs) {
                    HStack {
                        if let cap = u.limit {
                            Text("\(u.requestsThisMonth) / \(cap) requests this month")
                                .font(.flourishMeta)
                                .foregroundColor(.flourishTextSecondary)
                        } else {
                            Text("Unlimited requests")
                                .font(.flourishMeta)
                                .foregroundColor(.flourishTextSecondary)
                        }
                        Spacer()
                        if u.limit != nil {
                            Text("resets \(formattedReset(u.resetAt))")
                                .font(.flourishMeta)
                                .foregroundColor(.flourishTextTertiary)
                        }
                    }
                    if let cap = u.limit {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.flourishSurfaceRaised)
                                    .frame(height: 4)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.flourishAccent)
                                    .frame(
                                        width: geo.size.width * min(
                                            CGFloat(u.requestsThisMonth) / max(CGFloat(cap), 1),
                                            1.0
                                        ),
                                        height: 4
                                    )
                            }
                        }
                        .frame(height: 4)
                    }
                }
            }

            Button("Sign out") { Task { await auth.signOut() } }
                .font(.flourishMeta)
                .foregroundColor(.flourishTextTertiary)
                .buttonStyle(.plain)
                .pointerCursor()
        }
        .padding(.horizontal, FS.xxl)
        .padding(.top, FS.lg)
    }

    private func formattedReset(_ iso: String) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        guard let periodStart = df.date(from: iso) else { return iso }
        let nextReset = Calendar.current.date(byAdding: .month, value: 1, to: periodStart) ?? periodStart
        df.dateFormat = "MMM d"
        return df.string(from: nextReset)
    }
}

// MARK: - Billing Section

private struct BillingSection: View {
    @ObservedObject var vm: AccountViewModel
    @State private var billingPeriod: BillingPeriod = .monthly

    enum BillingPeriod: String, CaseIterable {
        case monthly = "Monthly"
        case annual = "Annual"
        /// Value expected by the /billing/checkout endpoint
        var apiValue: String { self == .annual ? "yearly" : "monthly" }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FS.lg) {
            AccountLabel("Plans and Billing")

            if let err = vm.billingError {
                Text(err).font(.flourishMeta).foregroundColor(.red.opacity(0.85))
            }

            // Billing period toggle — centred like the reference design
            HStack {
                Spacer()
                PlanBillingToggle(selected: $billingPeriod)
                Spacer()
            }

            // Three-column plans grid
            PlanCardsGrid(billingPeriod: billingPeriod, vm: vm)
        }
        .padding(.horizontal, FS.xxl)
        .padding(.top, 0)
        .padding(.bottom, FS.xxl)
    }
}

// MARK: - Billing Period Toggle

private struct PlanBillingToggle: View {
    @Binding var selected: BillingSection.BillingPeriod

    var body: some View {
        HStack(spacing: 0) {
            ForEach(BillingSection.BillingPeriod.allCases, id: \.self) { period in
                Button { selected = period } label: {
                    Text(period.rawValue)
                        .font(.flourishButton)
                        .foregroundColor(selected == period ? .flourishTextPrimary : .flourishTextSecondary)
                        .padding(.horizontal, FS.xxl)
                        .padding(.vertical, FS.sm)
                        .background(
                            selected == period
                                ? Color.flourishSurface
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: FS.radiusSm))
                        .shadow(
                            color: selected == period ? Color.black.opacity(0.06) : Color.clear,
                            radius: 3, x: 0, y: 1
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .pointerCursor()
            }
        }
        .padding(3)
        .background(Color.flourishSurfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: FS.radiusMd))
    }
}

// MARK: - Plans Grid

private struct PlanCardsGrid: View {
    let billingPeriod: BillingSection.BillingPeriod
    @ObservedObject var vm: AccountViewModel

    var body: some View {
        HStack(spacing: 0) {
            BasicPlanColumn()
            Rectangle().fill(Color.flourishBorder).frame(width: FS.borderWidth)
            ProPlanColumn(billingPeriod: billingPeriod, vm: vm)
        }
        .frame(maxWidth: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: FS.radiusLg)
                .stroke(Color.flourishBorder, lineWidth: FS.borderWidth)
        )
        .clipShape(RoundedRectangle(cornerRadius: FS.radiusLg))
    }
}

// MARK: - Basic Plan Column

private struct BasicPlanColumn: View {
    private let features = [
        "30 improvements per month",
        "Works in any app via hotkey",
        "Custom writing profiles",
        "Target platform formatting",
        "Full improvement history",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: FS.xs) {
                Text("For individuals")
                    .font(.flourishMeta)
                    .foregroundColor(.flourishTextSecondary)
                Text("Basic")
                    .font(.flourishTitle)
                    .foregroundColor(.flourishTextPrimary)
                Text("Free")
                    .font(.flourishBody)
                    .foregroundColor(.flourishTextPrimary)
            }
            .padding(FS.lg)
            .frame(maxWidth: .infinity, alignment: .leading)

            Rectangle().fill(Color.flourishBorder).frame(height: FS.borderWidth)

            // Features
            VStack(alignment: .leading, spacing: FS.md) {
                ForEach(features, id: \.self) { feature in
                    PlanFeatureRow(text: feature)
                }
            }
            .padding(FS.lg)

            Spacer(minLength: FS.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - Pro Plan Column

private struct ProPlanColumn: View {
    let billingPeriod: BillingSection.BillingPeriod
    @ObservedObject var vm: AccountViewModel

    private let features = [
        "Unlimited improvements",
        "Everything in Free",
        "Prioritized feature requests",
        "Early access to new features",
        "Priority support",
        "Cancel anytime",
    ]

    private var priceLabel: String {
        billingPeriod == .annual ? "29,99 € per year" : "2,99 € per month"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: FS.xs) {
                Text("For power users")
                    .font(.flourishMeta)
                    .foregroundColor(.flourishTextSecondary)
                HStack(spacing: FS.sm) {
                    Text("Pro")
                        .font(.flourishTitle)
                        .foregroundColor(.flourishTextPrimary)
                    if billingPeriod == .annual {
                        Text("-16%")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.flourishAccent)
                            .padding(.horizontal, FS.sm)
                            .padding(.vertical, 3)
                            .background(Color.flourishAccent.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                Text(priceLabel)
                    .font(.flourishBody)
                    .foregroundColor(.flourishTextPrimary)
            }
            .padding(FS.lg)
            .frame(maxWidth: .infinity, alignment: .leading)

            Rectangle().fill(Color.flourishBorder).frame(height: FS.borderWidth)

            // Features
            VStack(alignment: .leading, spacing: FS.md) {
                ForEach(features, id: \.self) { feature in
                    PlanFeatureRow(text: feature)
                }
            }
            .padding(FS.lg)

            Spacer(minLength: FS.lg)

            // CTA
            VStack(spacing: 0) {
                Rectangle().fill(Color.flourishBorder).frame(height: FS.borderWidth)
                if vm.usage?.plan == "pro" {
                    Button {
                        Task { await vm.openBillingPortal() }
                    } label: {
                        Text("Manage billing")
                            .font(.flourishButton)
                            .foregroundColor(.flourishButtonLabel)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, FS.md)
                            .background(Color.flourishButtonBg)
                            .clipShape(RoundedRectangle(cornerRadius: FS.radiusMd))
                            .contentShape(RoundedRectangle(cornerRadius: FS.radiusMd))
                    }
                    .buttonStyle(.plain)
                    .pointerCursor()
                    .padding(FS.lg)
                } else {
                    Button {
                        Task { await vm.openCheckout(billingPeriod: billingPeriod.apiValue) }
                    } label: {
                        Text("Upgrade to Pro")
                            .font(.flourishButton)
                            .foregroundColor(.flourishButtonLabel)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, FS.md)
                            .background(Color.flourishButtonBg)
                            .clipShape(RoundedRectangle(cornerRadius: FS.radiusMd))
                            .contentShape(RoundedRectangle(cornerRadius: FS.radiusMd))
                    }
                    .buttonStyle(.plain)
                    .pointerCursor()
                    .padding(FS.lg)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - Plan Feature Row

private struct PlanFeatureRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: FS.sm) {
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.flourishAccent)
                .frame(width: 14, height: 16)
            Text(text)
                .font(.flourishBody)
                .foregroundColor(.flourishTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Shared Sub-Views

private struct AccountLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text.uppercased())
            .font(.flourishMeta)
            .foregroundColor(.flourishTextTertiary)
            .tracking(0.8)
    }
}

private struct AccountSectionDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.flourishBorder)
            .frame(height: FS.borderWidth)
            .padding(.horizontal, FS.xxl)
            .padding(.vertical, FS.lg)
    }
}

private struct PlanBadge: View {
    let plan: String
    var isPro: Bool { plan == "pro" }
    var body: some View {
        Text(plan.uppercased())
            .font(.flourishMeta)
            .foregroundColor(isPro ? .flourishAccent : .flourishTextSecondary)
            .padding(.horizontal, FS.xs)
            .padding(.vertical, 2)
            .background(isPro ? Color.flourishAccent.opacity(0.12) : Color.flourishSurfaceRaised)
            .cornerRadius(FS.radiusSm)
    }
}
