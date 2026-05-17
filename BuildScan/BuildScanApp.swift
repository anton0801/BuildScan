import SwiftUI

@main
struct BuildScanApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ZStack {
                SplashView()
            }
        }
    }
}

// MARK: - Root View
struct RootView: View {
    @StateObject private var appState = AppState()
    @StateObject private var dataStore = DataStore()

    var body: some View {
        Group {
            if !appState.isLoggedIn {
                if !appState.hasCompletedOnboarding {
                    OnboardingView()
                        .environmentObject(appState)
                } else {
                    LoginContainer()
                        .environmentObject(appState)
                }
            } else {
                MainTabView()
                    .environmentObject(appState)
                    .environmentObject(dataStore)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: appState.isLoggedIn)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: appState.hasCompletedOnboarding)
    }
}

// MARK: - Login Container (with environment injection)
struct LoginContainer: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm: AuthViewModel
    @State private var isRegister = false

    init() {
        _vm = StateObject(wrappedValue: AuthViewModel(appState: AppState()))
    }

    var body: some View {
        LoginViewFull(isRegister: $isRegister)
            .environmentObject(appState)
    }
}

struct LoginViewFull: View {
    @EnvironmentObject var appState: AppState
    @State private var vm: AuthVM = AuthVM()
    @Binding var isRegister: Bool

    struct AuthVM {
        var name = ""
        var email = ""
        var password = ""
        var confirm = ""
        var isLoading = false
        var error = ""
    }

    var body: some View {
        ZStack {
            DS.Colors.bgPrimary.ignoresSafeArea()
            GridBackgroundView().opacity(0.12)

            ScrollView(showsIndicators: false) {
                VStack(spacing: DS.Spacing.xl) {
                    // Logo
                    VStack(spacing: DS.Spacing.m) {
                        ZStack {
                            Circle()
                                .fill(DS.Colors.cyanGlow)
                                .frame(width: 90, height: 90)
                                .blur(radius: 20)
                            RoundedRectangle(cornerRadius: 20)
                                .fill(DS.Colors.card)
                                .frame(width: 72, height: 72)
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(DS.Colors.cyan.opacity(0.5), lineWidth: 1))
                            CrackIconView().frame(width: 44, height: 44)
                        }

                        Text(isRegister ? "Create Account" : "Welcome Back")
                            .font(DS.Typography.display(28))
                            .foregroundColor(DS.Colors.textPrimary)

                        Text(isRegister ? "Start scanning today" : "Sign in to Build Scan")
                            .font(DS.Typography.body())
                            .foregroundColor(DS.Colors.textSecondary)
                    }
                    .padding(.top, 60)

                    // Demo Card
                    DSCard {
                        VStack(spacing: DS.Spacing.m) {
                            HStack(spacing: DS.Spacing.s) {
                                Image(systemName: "bolt.circle.fill")
                                    .foregroundColor(DS.Colors.cyan)
                                    .font(.system(size: 20))
                                Text("Demo Account")
                                    .font(DS.Typography.subheading())
                                    .foregroundColor(DS.Colors.textPrimary)
                                Spacer()
                                Text("FREE")
                                    .font(DS.Typography.caption(10))
                                    .foregroundColor(DS.Colors.btnPrimaryText)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(DS.Colors.cyan)
                                    .cornerRadius(DS.Radius.full)
                            }
                            Text("Try all features instantly — no sign up required")
                                .font(DS.Typography.caption())
                                .foregroundColor(DS.Colors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Button(action: { loginDemo() }) {
                                HStack(spacing: DS.Spacing.s) {
                                    if vm.isLoading {
                                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: DS.Colors.btnPrimaryText)).scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "arrow.right").font(.system(size: 16, weight: .semibold))
                                    }
                                    Text("Continue with Demo")
                                        .font(DS.Typography.subheading())
                                }
                                .foregroundColor(DS.Colors.btnPrimaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(LinearGradient(colors: [DS.Colors.cyan, DS.Colors.cyanActive], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .cornerRadius(DS.Radius.l)
                                .shadow(color: DS.Colors.cyanGlow, radius: 12, x: 0, y: 4)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                    .padding(.horizontal, DS.Spacing.l)

                    // Divider
                    HStack {
                        Rectangle().fill(DS.Colors.divider).frame(height: 1)
                        Text("or").font(DS.Typography.caption()).foregroundColor(DS.Colors.textMuted).padding(.horizontal, DS.Spacing.s)
                        Rectangle().fill(DS.Colors.divider).frame(height: 1)
                    }
                    .padding(.horizontal, DS.Spacing.l)

                    // Form
                    VStack(spacing: DS.Spacing.m) {
                        if isRegister {
                            BSTextField(placeholder: "Full Name", text: $vm.name, icon: "person.fill")
                        }
                        BSTextField(placeholder: "Email", text: $vm.email, icon: "envelope.fill")
                        BSTextField(placeholder: "Password", text: $vm.password, icon: "lock.fill", isSecure: true)
                        if isRegister {
                            BSTextField(placeholder: "Confirm Password", text: $vm.confirm, icon: "lock.fill", isSecure: true)
                        }

                        if !vm.error.isEmpty {
                            Text(vm.error)
                                .font(DS.Typography.caption())
                                .foregroundColor(DS.Colors.danger)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button(action: { isRegister ? register() : login() }) {
                            HStack(spacing: DS.Spacing.s) {
                                Image(systemName: "arrow.right").font(.system(size: 16, weight: .semibold))
                                Text(isRegister ? "Create Account" : "Sign In").font(DS.Typography.subheading())
                            }
                            .foregroundColor(DS.Colors.btnPrimaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(LinearGradient(colors: [DS.Colors.cyan, DS.Colors.cyanActive], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .cornerRadius(DS.Radius.l)
                            .shadow(color: DS.Colors.cyanGlow, radius: 12, x: 0, y: 4)
                        }
                        .buttonStyle(ScaleButtonStyle())

                        Button(action: { withAnimation { isRegister.toggle() } }) {
                            HStack(spacing: 4) {
                                Text(isRegister ? "Already have an account?" : "Don't have an account?").foregroundColor(DS.Colors.textMuted)
                                Text(isRegister ? "Sign In" : "Sign Up").foregroundColor(DS.Colors.cyan)
                            }
                            .font(DS.Typography.caption())
                        }
                    }
                    .padding(.horizontal, DS.Spacing.l)

                    Spacer(minLength: 40)
                }
            }
        }
    }

    private func loginDemo() {
        vm.isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            appState.userName = "Demo User"
            appState.userEmail = "demo@buildscan.app"
            appState.isLoggedIn = true
            vm.isLoading = false
        }
    }

    private func login() {
        guard !vm.email.isEmpty, !vm.password.isEmpty else {
            vm.error = "Please fill in all fields."
            return
        }
        vm.isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            appState.userName = "User"
            appState.userEmail = vm.email
            appState.isLoggedIn = true
            vm.isLoading = false
        }
    }

    private func register() {
        guard !vm.name.isEmpty, !vm.email.isEmpty, !vm.password.isEmpty else {
            vm.error = "Please fill in all fields."
            return
        }
        guard vm.password == vm.confirm else {
            vm.error = "Passwords do not match."
            return
        }
        vm.isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            appState.userName = vm.name
            appState.userEmail = vm.email
            appState.isLoggedIn = true
            vm.isLoading = false
        }
    }
}
