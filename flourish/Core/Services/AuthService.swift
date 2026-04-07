import Foundation
import Supabase
import Defaults

// MARK: - Auth User

struct AuthUser {
    let id: String
    let email: String
}

// MARK: - Auth Service

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var currentUser: AuthUser? = nil
    @Published var isLoading: Bool = false
    @Published var authError: String? = nil

    private let client: SupabaseClient

    private init() {
        let info = Bundle.main.infoDictionary
        // SUPABASE_URL stored without https:// — xcconfig treats // as a comment delimiter
        let host    = info?["SupabaseURL"] as? String ?? ""
        let anonKey = info?["SupabaseAnonKey"] as? String ?? ""
        guard let url = URL(string: "https://" + host), !host.isEmpty, !anonKey.isEmpty else {
            fatalError("Flourish: Missing Supabase config. Set SUPABASE_URL and SUPABASE_ANON_KEY in Flourish/Config/Secrets.xcconfig.")
        }
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: anonKey,
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(
                    storage: KeychainLocalStorage(service: "flourish", accessGroup: nil),
                    redirectToURL: URL(string: "flourish://auth/callback"),
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }

    // MARK: - Start observing auth state (call once on app launch)
    //
    // Uses the authStateChanges async stream as the single source of truth.
    // Every sign-in path — email, Google, Apple — resolves here.

    func startObservingAuthState() {
        Task {
            for await (event, session) in client.auth.authStateChanges {
                switch event {
                case .initialSession, .signedIn, .tokenRefreshed, .userUpdated:
                    if let session {
                        currentUser = AuthUser(
                            id: session.user.id.uuidString,
                            email: session.user.email ?? ""
                        )
                        isLoading = false
                        SignInWindowController.shared.hide()
                        // Request accessibility after login — user has context for why it's needed
                        if !PasteService.shared.checkAccessibilityPermission() {
                            PasteService.shared.requestAccessibilityPermission()
                        }
                        await ensureAccountExists()
                    }
                case .signedOut, .userDeleted:
                    currentUser = nil
                    isLoading = false
                    Defaults[.lastKnownSubscription] = "free"
                    MainWindowController.shared.window?.orderOut(nil)
                    SignInWindowController.shared.show()
                case .passwordRecovery, .mfaChallengeVerified:
                    break
                }
            }
        }
    }

    // MARK: - Sign In (email + password)

    func signIn(email: String, password: String) async {
        isLoading = true; authError = nil
        do {
            try await client.auth.signIn(email: email, password: password)
            // currentUser is set by the authStateChanges stream
        } catch {
            authError = friendlyError(error)
            isLoading = false
        }
    }

    // MARK: - Sign Up (email + password)

    func signUp(email: String, password: String) async {
        isLoading = true; authError = nil
        do {
            try await client.auth.signUp(email: email, password: password)
            // currentUser is set by the authStateChanges stream on .signedIn
        } catch {
            authError = friendlyError(error)
            isLoading = false
        }
    }

    // MARK: - OAuth (opens system browser — callback arrives via deep link)

    func signInWithGoogle() async {
        isLoading = true; authError = nil
        do {
            try await client.auth.signInWithOAuth(provider: .google)
            // Browser is now open; isLoading stays true until the deep-link
            // callback triggers .signedIn in authStateChanges
        } catch {
            authError = friendlyError(error)
            isLoading = false
        }
    }

    // MARK: - Handle OAuth deep-link callback (called by AppDelegate)

    func handleAuthCallback(url: URL) async {
        do {
            // session(from:) exchanges the OAuth code for a session and stores it.
            // The authStateChanges stream then emits .signedIn which sets currentUser.
            try await client.auth.session(from: url)
        } catch {
            authError = friendlyError(error)
            isLoading = false
        }
    }

    // MARK: - Sign Out

    func signOut() async {
        try? await client.auth.signOut()
        // currentUser is cleared by the authStateChanges stream on .signedOut
    }

    // MARK: - Access Token (used by FlourishProxyService on every LLM call)

    func currentAccessToken() async -> String? {
        return try? await client.auth.session.accessToken
    }

    // MARK: - Create account row in Worker D1 (idempotent, fire-and-forget)

    private func ensureAccountExists() async {
        guard let token = await currentAccessToken() else { return }
        var req = URLRequest(url: proxyURL(path: "account/create"))
        req.httpMethod = "POST"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = Data("{}".utf8)
        _ = try? await URLSession.shared.data(for: req)
    }

    // MARK: - Helpers

    private func proxyURL(path: String) -> URL {
        let base = Bundle.main.infoDictionary?["flourishProxyURL"] as? String ?? ""
        return URL(string: "https://\(base)/\(path)")!
    }

    private func friendlyError(_ error: Error) -> String {
        let msg = error.localizedDescription
        if msg.contains("Invalid login credentials") { return "Incorrect email or password." }
        if msg.contains("Email not confirmed")       { return "Check your email to confirm your account." }
        if msg.contains("User already registered")   { return "An account with this email already exists. Sign in instead." }
        return msg
    }
}
