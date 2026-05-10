import SwiftUI

// MARK: - Login View
struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm: AuthViewModel
    @State private var isRegister = false
    @Environment(\.dismiss) var dismiss

    init() {
        _vm = StateObject(wrappedValue: AuthViewModel(appState: AppState()))
    }

    var body: some View {
        ZStack {
            DS.Colors.bgPrimary.ignoresSafeArea()
            GridBackgroundView().opacity(0.12)

            ScrollView(showsIndicators: false) {
                VStack(spacing: DS.Spacing.xl) {
                    // Header
                    VStack(spacing: DS.Spacing.m) {
                        ZStack {
                            Circle()
                                .fill(DS.Colors.cyanGlow)
                                .frame(width: 90, height: 90)
                                .blur(radius: 20)

                            RoundedRectangle(cornerRadius: 20)
                                .fill(DS.Colors.card)
                                .frame(width: 72, height: 72)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(DS.Colors.cyan.opacity(0.5), lineWidth: 1)
                                )

                            CrackIconView().frame(width: 44, height: 44)
                        }

                        Text(isRegister ? "Create Account" : "Welcome Back")
                            .font(DS.Typography.display(28))
                            .foregroundColor(DS.Colors.textPrimary)

                        Text(isRegister ? "Start scanning your walls today" : "Sign in to continue scanning")
                            .font(DS.Typography.body())
                            .foregroundColor(DS.Colors.textSecondary)
                    }
                    .padding(.top, 60)

                    // Demo button - prominently visible
                    DSCard {
                        VStack(spacing: DS.Spacing.m) {
                            HStack(spacing: DS.Spacing.s) {
                                Image(systemName: "bolt.circle.fill")
                                    .foregroundColor(DS.Colors.cyan)
                                Text("Try Demo Account")
                                    .font(DS.Typography.subheading())
                                    .foregroundColor(DS.Colors.textPrimary)
                                Spacer()
                            }
                            Text("Explore all features instantly — no sign up required")
                                .font(DS.Typography.caption())
                                .foregroundColor(DS.Colors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            PrimaryButton("Continue with Demo", icon: "arrow.right") {
                                vm.loginWithDemo()
                            }
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
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        BSTextField(placeholder: "Password", text: $vm.password, icon: "lock.fill", isSecure: true)
                        if isRegister {
                            BSTextField(placeholder: "Confirm Password", text: $vm.confirmPassword, icon: "lock.fill", isSecure: true)
                        }

                        if !vm.errorMessage.isEmpty {
                            Text(vm.errorMessage)
                                .font(DS.Typography.caption())
                                .foregroundColor(DS.Colors.danger)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 4)
                        }

                        PrimaryButton(
                            isRegister ? "Create Account" : "Sign In",
                            icon: "arrow.right",
                            isLoading: vm.isLoading
                        ) {
                            if isRegister { vm.register() } else { vm.login() }
                        }

                        Button(action: { withAnimation { isRegister.toggle() } }) {
                            HStack(spacing: 4) {
                                Text(isRegister ? "Already have an account?" : "Don't have an account?")
                                    .foregroundColor(DS.Colors.textMuted)
                                Text(isRegister ? "Sign In" : "Sign Up")
                                    .foregroundColor(DS.Colors.cyan)
                            }
                            .font(DS.Typography.caption())
                        }
                    }
                    .padding(.horizontal, DS.Spacing.l)

                    Spacer(minLength: 40)
                }
            }
        }
        .onChange(of: appState.isLoggedIn) { val in
            if val { dismiss() }
        }
        .onAppear {
            // Re-init vm with the actual appState from environment
        }
    }
}

// Workaround: use environment appState
struct LoginViewWrapper: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm: AuthViewModel
    @State private var isRegister = false
    @Environment(\.dismiss) var dismiss

    init(appState: AppState) {
        _vm = StateObject(wrappedValue: AuthViewModel(appState: appState))
    }

    var body: some View {
        ZStack {
            DS.Colors.bgPrimary.ignoresSafeArea()
            GridBackgroundView().opacity(0.12)

            ScrollView(showsIndicators: false) {
                VStack(spacing: DS.Spacing.xl) {
                    // Header
                    VStack(spacing: DS.Spacing.m) {
                        ZStack {
                            Circle()
                                .fill(DS.Colors.cyanGlow)
                                .frame(width: 90, height: 90)
                                .blur(radius: 20)

                            RoundedRectangle(cornerRadius: 20)
                                .fill(DS.Colors.card)
                                .frame(width: 72, height: 72)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(DS.Colors.cyan.opacity(0.5), lineWidth: 1)
                                )

                            CrackIconView().frame(width: 44, height: 44)
                        }

                        Text(isRegister ? "Create Account" : "Welcome Back")
                            .font(DS.Typography.display(28))
                            .foregroundColor(DS.Colors.textPrimary)

                        Text(isRegister ? "Start scanning your walls today" : "Sign in to continue scanning")
                            .font(DS.Typography.body())
                            .foregroundColor(DS.Colors.textSecondary)
                    }
                    .padding(.top, 60)

                    // Demo button
                    DSCard {
                        VStack(spacing: DS.Spacing.m) {
                            HStack(spacing: DS.Spacing.s) {
                                Image(systemName: "bolt.circle.fill")
                                    .foregroundColor(DS.Colors.cyan)
                                    .font(.system(size: 20))
                                Text("Try Demo Account")
                                    .font(DS.Typography.subheading())
                                    .foregroundColor(DS.Colors.textPrimary)
                                Spacer()
                                Text("FREE")
                                    .font(DS.Typography.caption(10))
                                    .foregroundColor(DS.Colors.btnPrimaryText)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(DS.Colors.cyan)
                                    .cornerRadius(DS.Radius.full)
                            }
                            Text("Explore all features instantly — no sign up required")
                                .font(DS.Typography.caption())
                                .foregroundColor(DS.Colors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            PrimaryButton("Continue with Demo", icon: "arrow.right", isLoading: vm.isLoading) {
                                vm.loginWithDemo()
                            }
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
                            BSTextField(placeholder: "Confirm Password", text: $vm.confirmPassword, icon: "lock.fill", isSecure: true)
                        }

                        if !vm.errorMessage.isEmpty {
                            Text(vm.errorMessage)
                                .font(DS.Typography.caption())
                                .foregroundColor(DS.Colors.danger)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 4)
                        }

                        PrimaryButton(
                            isRegister ? "Create Account" : "Sign In",
                            icon: "arrow.right",
                            isLoading: vm.isLoading
                        ) {
                            if isRegister { vm.register() } else { vm.login() }
                        }

                        Button(action: { withAnimation { isRegister.toggle() } }) {
                            HStack(spacing: 4) {
                                Text(isRegister ? "Already have an account?" : "Don't have an account?")
                                    .foregroundColor(DS.Colors.textMuted)
                                Text(isRegister ? "Sign In" : "Sign Up")
                                    .foregroundColor(DS.Colors.cyan)
                            }
                            .font(DS.Typography.caption())
                        }
                    }
                    .padding(.horizontal, DS.Spacing.l)
                    Spacer(minLength: 40)
                }
            }
        }
        .onChange(of: appState.isLoggedIn) { val in
            if val { dismiss() }
        }
    }
}

// MARK: - Text Field
struct BSTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var isSecure: Bool = false
    @State private var showPassword: Bool = false
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: DS.Spacing.m) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(isFocused ? DS.Colors.cyan : DS.Colors.textMuted)
                .frame(width: 20)

            if isSecure && !showPassword {
                SecureField(placeholder, text: $text)
                    .font(DS.Typography.body())
                    .foregroundColor(DS.Colors.textPrimary)
                    .focused($isFocused)
            } else {
                TextField(placeholder, text: $text)
                    .font(DS.Typography.body())
                    .foregroundColor(DS.Colors.textPrimary)
                    .focused($isFocused)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }

            if isSecure {
                Button(action: { showPassword.toggle() }) {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 14))
                        .foregroundColor(DS.Colors.textMuted)
                }
            }
        }
        .padding(DS.Spacing.m)
        .background(DS.Colors.card)
        .cornerRadius(DS.Radius.m)
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.m)
                .stroke(isFocused ? DS.Colors.cyan.opacity(0.6) : DS.Colors.divider, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}
