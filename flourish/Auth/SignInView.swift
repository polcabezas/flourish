import SwiftUI

// MARK: - Sign In View
// Compact auth panel — shown in SignInWindowController when user is not authenticated.

struct SignInView: View {
    @ObservedObject private var auth = AuthService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false

    var body: some View {
        VStack(spacing: 0) {
            // ── Header — sage green banner (mirrors LimitReachedPopupView right panel) ──
            // .ignoresSafeArea fills behind the transparent title bar so no white gap appears.
            // The logo is offset by half the title bar height so it appears centered in
            // the visible green area below the traffic lights.
            ZStack {
                Color(hex: "#C8DFC0")
                flourishWordmarkView(height: 34, color: Color(hex: "#3D6135"))
                    .offset(y: 14) // half of ~28pt title bar → visually centers logo
            }
            .frame(maxWidth: .infinity, minHeight: 100)
            .ignoresSafeArea(edges: .top)

            // ── Form ──────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 12) {

                // Email
                VStack(alignment: .leading, spacing: 4) {
                    Text("Email")
                        .font(.flourishMeta)
                        .foregroundColor(.flourishTextSecondary)
                    TextField("you@example.com", text: $email)
                        .font(.flourishBody)
                        .foregroundColor(.flourishTextPrimary)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.flourishSurfaceRaised)
                        .cornerRadius(FS.radiusSm)
                        .overlay(RoundedRectangle(cornerRadius: FS.radiusSm)
                            .stroke(Color.flourishBorder, lineWidth: FS.borderWidth))
                }

                // Password
                VStack(alignment: .leading, spacing: 4) {
                    Text("Password")
                        .font(.flourishMeta)
                        .foregroundColor(.flourishTextSecondary)
                    SecureField("••••••••", text: $password)
                        .font(.flourishBody)
                        .foregroundColor(.flourishTextPrimary)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.flourishSurfaceRaised)
                        .cornerRadius(FS.radiusSm)
                        .overlay(RoundedRectangle(cornerRadius: FS.radiusSm)
                            .stroke(Color.flourishBorder, lineWidth: FS.borderWidth))
                }

                // Error
                if let err = auth.authError {
                    Text(err)
                        .font(.flourishMeta)
                        .foregroundColor(.red.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Primary button
                Button {
                    Task {
                        if isSignUp { await auth.signUp(email: email, password: password) }
                        else        { await auth.signIn(email: email, password: password) }
                    }
                } label: {
                    HStack(spacing: 6) {
                        if auth.isLoading { ProgressView().scaleEffect(0.45).frame(width: 16, height: 16) }
                        Text(isSignUp ? "Create account" : "Sign in")
                            .font(.flourishButton)
                            .foregroundColor(.flourishButtonLabel)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.flourishButtonBg)
                    .cornerRadius(FS.radiusSm)
                }
                .buttonStyle(.plain)
                .pointerCursor()
                .disabled(auth.isLoading || email.isEmpty || password.count < 6)

                // Toggle sign-up / sign-in
                HStack {
                    Spacer()
                    Button(isSignUp ? "Already have an account? Sign in" : "No account? Create one") {
                        isSignUp.toggle()
                        auth.authError = nil
                    }
                    .font(.flourishMeta)
                    .foregroundColor(.flourishTextSecondary)
                    .buttonStyle(.plain)
                    .pointerCursor()
                    Spacer()
                }

                // Divider
                HStack {
                    Rectangle().fill(Color.flourishBorder).frame(height: FS.borderWidth)
                    Text("or").font(.flourishMeta).foregroundColor(.flourishTextTertiary)
                    Rectangle().fill(Color.flourishBorder).frame(height: FS.borderWidth)
                }
                .padding(.vertical, 2)

                // Google OAuth button
                Button {
                    Task { await auth.signInWithGoogle() }
                } label: {
                    HStack(spacing: 8) {
                        if auth.isLoading {
                            ProgressView().scaleEffect(0.45).frame(width: 16, height: 16)
                        } else {
                            Image("GoogleLogo")
                                .resizable()
                                .interpolation(.high)
                                .frame(width: 16, height: 16)
                        }
                        Text("Continue with Google")
                            .font(.flourishButton)
                            .foregroundColor(.flourishTextPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.flourishSurfaceRaised)
                    .cornerRadius(FS.radiusSm)
                    .overlay(RoundedRectangle(cornerRadius: FS.radiusSm)
                        .stroke(Color.flourishBorder, lineWidth: FS.borderWidth))
                }
                .buttonStyle(.plain)
                .pointerCursor()
                .disabled(auth.isLoading)
            }
            .padding(.horizontal, 28)
            .padding(.top, 20)

            Spacer(minLength: 28)
        }
        .frame(width: 320)
        .background(Color.flourishSurface)
    }
}
