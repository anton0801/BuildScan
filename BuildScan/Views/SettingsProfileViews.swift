import SwiftUI
import UserNotifications

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var settingsVM: SettingsViewModel
    @State private var showProfile = false
    @State private var showDeleteConfirm = false
    @State private var showLogoutConfirm = false
    @State private var savedFeedback = false

    init() {
        _settingsVM = StateObject(wrappedValue: SettingsViewModel(appState: AppState()))
    }

    var body: some View {
        NavigationView {
            ZStack {
                DS.Colors.bgPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DS.Spacing.l) {
                        // Header
                        HStack {
                            Text("Settings")
                                .font(DS.Typography.display(26))
                                .foregroundColor(DS.Colors.textPrimary)
                            Spacer()
                        }
                        .padding(.horizontal, DS.Spacing.l)
                        .padding(.top, DS.Spacing.l)

                        // Profile card
                        Button(action: { showProfile = true }) {
                            DSCard {
                                HStack(spacing: DS.Spacing.m) {
                                    ZStack {
                                        Circle()
                                            .fill(DS.Colors.cyanGlow)
                                            .frame(width: 52, height: 52)
                                        Text(initials(appState.userName))
                                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                                            .foregroundColor(DS.Colors.btnPrimaryText)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(appState.userName.isEmpty ? "User" : appState.userName)
                                            .font(DS.Typography.subheading())
                                            .foregroundColor(DS.Colors.textPrimary)
                                        Text(appState.userEmail)
                                            .font(DS.Typography.caption())
                                            .foregroundColor(DS.Colors.textMuted)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(DS.Colors.textMuted)
                                }
                            }
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.horizontal, DS.Spacing.l)

                        // Appearance
                        SettingsSection(title: "Appearance") {
                            SettingsPickerRow(
                                icon: "paintbrush.fill",
                                label: "Theme",
                                color: DS.Colors.purple,
                                selection: Binding(
                                    get: { appState.appTheme },
                                    set: { appState.appTheme = $0 }
                                ),
                                options: ["system", "dark", "light"],
                                displayNames: ["System", "Dark", "Light"]
                            )

                            Divider().background(DS.Colors.divider).padding(.horizontal, DS.Spacing.m)

                            SettingsPickerRow(
                                icon: "ruler.fill",
                                label: "Units",
                                color: DS.Colors.cyan,
                                selection: Binding(
                                    get: { appState.measurementUnit },
                                    set: { appState.measurementUnit = $0 }
                                ),
                                options: ["mm", "cm", "in"],
                                displayNames: ["Millimeters (mm)", "Centimeters (cm)", "Inches (in)"]
                            )
                        }
                        .padding(.horizontal, DS.Spacing.l)

                        // AI Analysis
                        SettingsSection(title: "AI Analysis") {
                            SettingsToggleRow(
                                icon: "waveform.path.ecg",
                                label: "AI-Powered Analysis",
                                subtitle: "Use AI to classify crack types and risk",
                                color: DS.Colors.purple,
                                isOn: Binding(
                                    get: { appState.aiAnalysisEnabled },
                                    set: { appState.aiAnalysisEnabled = $0 }
                                )
                            )
                        }
                        .padding(.horizontal, DS.Spacing.l)

                        // Notifications
                        SettingsSection(title: "Notifications") {
                            SettingsToggleRow(
                                icon: "bell.fill",
                                label: "Push Notifications",
                                subtitle: "Reminders to check your walls",
                                color: DS.Colors.warning,
                                isOn: Binding(
                                    get: { appState.notificationsEnabled },
                                    set: { settingsVM.requestNotificationPermission(enabled: $0) }
                                )
                            )

                            if appState.notificationsEnabled {
                                Divider().background(DS.Colors.divider).padding(.horizontal, DS.Spacing.m)

                                SettingsToggleRow(
                                    icon: "doc.text.fill",
                                    label: "Weekly Report",
                                    subtitle: "Monday morning wall health summary",
                                    color: DS.Colors.cyan,
                                    isOn: Binding(
                                        get: { appState.weeklyReportEnabled },
                                        set: {
                                            appState.weeklyReportEnabled = $0
                                            settingsVM.scheduleWeeklyReport(enabled: $0)
                                        }
                                    )
                                )

                                Divider().background(DS.Colors.divider).padding(.horizontal, DS.Spacing.m)

                                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                                    HStack {
                                        Image(systemName: "calendar.badge.clock")
                                            .foregroundColor(DS.Colors.safe)
                                            .frame(width: 28)
                                        Text("Scan Reminder")
                                            .font(DS.Typography.body())
                                            .foregroundColor(DS.Colors.textPrimary)
                                        Spacer()
                                        Text("Every \(appState.reminderDays)d")
                                            .font(DS.Typography.caption())
                                            .foregroundColor(DS.Colors.textMuted)
                                    }
                                    Slider(
                                        value: Binding(
                                            get: { Double(appState.reminderDays) },
                                            set: {
                                                appState.reminderDays = Int($0)
                                                if appState.notificationsEnabled {
                                                    settingsVM.scheduleReminder()
                                                }
                                            }
                                        ),
                                        in: 7...90,
                                        step: 7
                                    )
                                    .tint(DS.Colors.safe)
                                }
                                .padding(.horizontal, DS.Spacing.m)
                                .padding(.vertical, DS.Spacing.s)
                            }
                        }
                        .padding(.horizontal, DS.Spacing.l)

                        // About
                        SettingsSection(title: "About") {
                            SettingsInfoRow(icon: "info.circle.fill", label: "Version", value: "1.0.0", color: DS.Colors.cyan)
                            Divider().background(DS.Colors.divider).padding(.horizontal, DS.Spacing.m)
                            SettingsInfoRow(icon: "envelope.fill", label: "Contact Support", value: "support@buildscan.app", color: DS.Colors.purple)
                        }
                        .padding(.horizontal, DS.Spacing.l)

                        // Account actions
                        VStack(spacing: DS.Spacing.m) {
                            // Logout
                            Button(action: { showLogoutConfirm = true }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .foregroundColor(DS.Colors.warning)
                                        .frame(width: 28)
                                    Text("Log Out")
                                        .font(DS.Typography.subheading(14))
                                        .foregroundColor(DS.Colors.warning)
                                    Spacer()
                                }
                                .padding(DS.Spacing.m)
                                .background(DS.Colors.warning.opacity(0.08))
                                .cornerRadius(DS.Radius.l)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DS.Radius.l)
                                        .stroke(DS.Colors.warning.opacity(0.2), lineWidth: 1)
                                )
                            }

                            // Delete account
                            Button(action: { showDeleteConfirm = true }) {
                                HStack {
                                    Image(systemName: "trash.fill")
                                        .foregroundColor(DS.Colors.danger)
                                        .frame(width: 28)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Delete Account")
                                            .font(DS.Typography.subheading(14))
                                            .foregroundColor(DS.Colors.danger)
                                        Text("Permanently removes all data")
                                            .font(DS.Typography.caption(11))
                                            .foregroundColor(DS.Colors.danger.opacity(0.7))
                                    }
                                    Spacer()
                                }
                                .padding(DS.Spacing.m)
                                .background(DS.Colors.danger.opacity(0.08))
                                .cornerRadius(DS.Radius.l)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DS.Radius.l)
                                        .stroke(DS.Colors.danger.opacity(0.2), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, DS.Spacing.l)

                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showProfile) {
                ProfileView()
                    .environmentObject(appState)
            }
            .alert("Log Out?", isPresented: $showLogoutConfirm) {
                Button("Log Out", role: .destructive) { appState.logout() }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Delete Account?", isPresented: $showDeleteConfirm) {
                Button("Delete Everything", role: .destructive) { appState.deleteAccount() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete your account and all scan data. This cannot be undone.")
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            // Sync settingsVM with environment appState
        }
    }

    private func initials(_ name: String) -> String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1)) + String(parts[1].prefix(1))
        }
        return String(name.prefix(2)).uppercased()
    }
}

// MARK: - Settings Components
struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            Text(title.uppercased())
                .font(DS.Typography.caption(11))
                .foregroundColor(DS.Colors.textMuted)
                .tracking(1)

            DSCard(padding: 0) {
                VStack(spacing: 0) {
                    content
                }
            }
        }
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let label: String
    let subtitle: String
    let color: Color
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: DS.Spacing.m) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(DS.Typography.body())
                    .foregroundColor(DS.Colors.textPrimary)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(DS.Typography.caption(11))
                        .foregroundColor(DS.Colors.textMuted)
                }
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .tint(DS.Colors.cyan)
                .labelsHidden()
        }
        .padding(DS.Spacing.m)
    }
}

struct SettingsPickerRow: View {
    let icon: String
    let label: String
    let color: Color
    @Binding var selection: String
    let options: [String]
    let displayNames: [String]

    var selectedDisplay: String {
        if let idx = options.firstIndex(of: selection) { return displayNames[idx] }
        return selection
    }

    var body: some View {
        HStack(spacing: DS.Spacing.m) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 28)

            Text(label)
                .font(DS.Typography.body())
                .foregroundColor(DS.Colors.textPrimary)

            Spacer()

            Picker("", selection: $selection) {
                ForEach(Array(zip(options, displayNames)), id: \.0) { opt, name in
                    Text(name).tag(opt)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .tint(DS.Colors.cyan)
        }
        .padding(DS.Spacing.m)
    }
}

struct SettingsInfoRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: DS.Spacing.m) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 28)
            Text(label)
                .font(DS.Typography.body())
                .foregroundColor(DS.Colors.textPrimary)
            Spacer()
            Text(value)
                .font(DS.Typography.caption())
                .foregroundColor(DS.Colors.textMuted)
        }
        .padding(DS.Spacing.m)
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var saved = false

    var body: some View {
        NavigationView {
            ZStack {
                DS.Colors.bgPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DS.Spacing.xl) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(DS.Colors.cyanGlow)
                                .frame(width: 100, height: 100)
                                .blur(radius: 20)

                            Circle()
                                .fill(DS.Colors.card)
                                .frame(width: 80, height: 80)
                                .overlay(Circle().stroke(DS.Colors.cyan, lineWidth: 1.5))

                            Text(initials(name.isEmpty ? appState.userName : name))
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(DS.Colors.cyan)
                        }
                        .padding(.top, DS.Spacing.xl)

                        // Form
                        VStack(spacing: DS.Spacing.m) {
                            BSTextField(placeholder: "Full Name", text: $name, icon: "person.fill")
                            BSTextField(placeholder: "Email", text: $email, icon: "envelope.fill")
                        }
                        .padding(.horizontal, DS.Spacing.l)

                        if saved {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(DS.Colors.safe)
                                Text("Profile saved successfully!")
                                    .font(DS.Typography.caption())
                                    .foregroundColor(DS.Colors.safe)
                            }
                        }

                        PrimaryButton("Save Profile", icon: "checkmark.circle") {
                            if !name.isEmpty { appState.userName = name }
                            if !email.isEmpty { appState.userEmail = email }
                            withAnimation { saved = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { saved = false }
                            }
                        }
                        .padding(.horizontal, DS.Spacing.l)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(DS.Colors.cyan)
                }
            }
            .onAppear {
                name = appState.userName
                email = appState.userEmail
            }
        }
    }

    private func initials(_ name: String) -> String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 { return String(parts[0].prefix(1)) + String(parts[1].prefix(1)) }
        return String(name.prefix(2)).uppercased()
    }
}
