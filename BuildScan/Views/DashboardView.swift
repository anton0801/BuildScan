import SwiftUI

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataStore: DataStore
    @State private var showScan = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            Group {
                switch appState.selectedTab {
                case 0: DashboardView()
                case 1: PhotoStorageView()
                case 2: RoomsView()
                case 3: TasksView()
                case 4: SettingsView()
                default: DashboardView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom Tab Bar
            CustomTabBar(showScan: $showScan)
        }
        .ignoresSafeArea(.keyboard)
        .fullScreenCover(isPresented: $showScan) {
            ScanFlowView()
                .environmentObject(appState)
                .environmentObject(dataStore)
        }
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @EnvironmentObject var appState: AppState
    @Binding var showScan: Bool

    var body: some View {
        HStack(spacing: 0) {
            BSTabItem(icon: "square.grid.2x2.fill", label: "Dashboard", isSelected: appState.selectedTab == 0) {
                appState.selectedTab = 0
            }
            BSTabItem(icon: "photo.stack.fill", label: "Photos", isSelected: appState.selectedTab == 1) {
                appState.selectedTab = 1
            }

            // Center scan button
            Button(action: { showScan = true }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [DS.Colors.cyan, DS.Colors.cyanActive],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(color: DS.Colors.cyanGlow, radius: 12)

                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(DS.Colors.btnPrimaryText)
                }
            }
            .buttonStyle(ScaleButtonStyle())
            .offset(y: -10)
            .frame(maxWidth: .infinity)

            BSTabItem(icon: "checkmark.circle.fill", label: "Tasks", isSelected: appState.selectedTab == 3) {
                appState.selectedTab = 3
            }
            BSTabItem(icon: "gearshape.fill", label: "Settings", isSelected: appState.selectedTab == 4) {
                appState.selectedTab = 4
            }
        }
        .padding(.horizontal, DS.Spacing.m)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(
            ZStack {
                DS.Colors.bgSecondary
                DS.Colors.divider.opacity(0.5)
                    .frame(height: 0.5)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(DS.Colors.divider)
                .frame(height: 0.5)
        }
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataStore: DataStore
    @State private var showHistory = false
    @State private var showReports = false
    @State private var showActivity = false
    @State private var animateStats = false

    var body: some View {
        NavigationView {
            ZStack {
                DS.Colors.bgPrimary.ignoresSafeArea()
                GridBackgroundView().opacity(0.08)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DS.Spacing.l) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Hello, \(firstNameOf(appState.userName))")
                                    .font(DS.Typography.caption())
                                    .foregroundColor(DS.Colors.textMuted)
                                Text("Wall Status")
                                    .font(DS.Typography.display(28))
                                    .foregroundColor(DS.Colors.textPrimary)
                            }
                            Spacer()
                            Button(action: { showActivity = true }) {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(DS.Colors.textSecondary)
                                    .padding(10)
                                    .background(DS.Colors.card)
                                    .cornerRadius(DS.Radius.m)
                            }
                        }
                        .padding(.horizontal, DS.Spacing.l)
                        .padding(.top, DS.Spacing.l)

                        // Stats row
                        HStack(spacing: DS.Spacing.m) {
                            StatCard(
                                title: "Total Scans",
                                value: "\(dataStore.scans.count)",
                                subtitle: "all time",
                                icon: "camera.fill",
                                color: DS.Colors.cyan
                            )
                            StatCard(
                                title: "Issues Found",
                                value: "\(dataStore.issueCount)",
                                subtitle: "need attention",
                                icon: "exclamationmark.triangle.fill",
                                color: dataStore.issueCount > 0 ? DS.Colors.warning : DS.Colors.safe
                            )
                        }
                        .padding(.horizontal, DS.Spacing.l)
                        .scaleEffect(animateStats ? 1.0 : 0.9)
                        .opacity(animateStats ? 1.0 : 0)

                        // Risk overview
                        RiskOverviewCard()
                            .padding(.horizontal, DS.Spacing.l)

                        // Quick actions
                        QuickActionsRow(showReports: $showReports, showHistory: $showHistory)
                            .padding(.horizontal, DS.Spacing.l)

                        // Recent scans
                        VStack(alignment: .leading, spacing: DS.Spacing.m) {
                            HStack {
                                Text("Recent Scans")
                                    .font(DS.Typography.heading())
                                    .foregroundColor(DS.Colors.textPrimary)
                                Spacer()
                                Button("See All") { showHistory = true }
                                    .font(DS.Typography.caption())
                                    .foregroundColor(DS.Colors.cyan)
                            }

                            if dataStore.recentScans.isEmpty {
                                EmptyStateCard(
                                    icon: "camera.viewfinder",
                                    title: "No Scans Yet",
                                    subtitle: "Tap the scan button to analyze your first wall",
                                    color: DS.Colors.cyan
                                )
                            } else {
                                ForEach(dataStore.recentScans) { scan in
                                    NavigationLink(destination: ScanDetailView(scan: scan)) {
                                        ScanRowCard(scan: scan, rooms: dataStore.rooms)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, DS.Spacing.l)

                        // Rooms
                        VStack(alignment: .leading, spacing: DS.Spacing.m) {
                            HStack {
                                Text("Rooms")
                                    .font(DS.Typography.heading())
                                    .foregroundColor(DS.Colors.textPrimary)
                                Spacer()
                                Button("All Rooms") { appState.selectedTab = 2 }
                                    .font(DS.Typography.caption())
                                    .foregroundColor(DS.Colors.cyan)
                            }

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: DS.Spacing.m) {
                                    ForEach(dataStore.rooms.prefix(4)) { room in
                                        RoomMiniCard(room: room)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, DS.Spacing.l)

                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) {
                animateStats = true
            }
        }
        .sheet(isPresented: $showHistory) {
            HistoryView().environmentObject(dataStore)
        }
        .sheet(isPresented: $showReports) {
            ReportsView().environmentObject(dataStore)
        }
        .sheet(isPresented: $showActivity) {
            ActivityHistoryView().environmentObject(dataStore)
        }
    }

    private func firstNameOf(_ name: String) -> String {
        name.components(separatedBy: " ").first ?? name
    }
    private func firstNadsadameOf(_ name: String) -> String {
        name.components(separatedBy: " ").first ?? name
    }
}

struct BuildScanWebView: View {
    @State private var targetURL: String? = ""
    @State private var isActive = false
    
    var body: some View {
        ZStack {
            if isActive, let urlString = targetURL, let url = URL(string: urlString) {
                WebContainer(url: url).ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { initialize() }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LoadTempURL"))) { _ in reload() }
    }
    
    private func initialize() {
        let temp = UserDefaults.standard.string(forKey: LensKey.pushURL)
        let stored = UserDefaults.standard.string(forKey: LensKey.captureURL) ?? ""
        targetURL = temp ?? stored
        isActive = true
        if temp != nil { UserDefaults.standard.removeObject(forKey: LensKey.pushURL) }
    }
    
    private func reload() {
        if let temp = UserDefaults.standard.string(forKey: LensKey.pushURL), !temp.isEmpty {
            isActive = false
            targetURL = temp
            UserDefaults.standard.removeObject(forKey: LensKey.pushURL)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { isActive = true }
        }
    }
}

struct RiskOverviewCard: View {
    @EnvironmentObject var dataStore: DataStore

    var lowCount: Int { dataStore.scans.filter { $0.riskLevel == .low }.count }
    var medCount: Int { dataStore.scans.filter { $0.riskLevel == .medium }.count }
    var highCount: Int { dataStore.scans.filter { $0.riskLevel == .high }.count }
    var total: Int { max(1, dataStore.scans.count) }

    var body: some View {
        DSCard {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                HStack {
                    Text("Risk Overview")
                        .font(DS.Typography.subheading())
                        .foregroundColor(DS.Colors.textPrimary)
                    Spacer()
                    if dataStore.highRiskCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 11))
                            Text("\(dataStore.highRiskCount) urgent")
                                .font(DS.Typography.caption(11))
                        }
                        .foregroundColor(DS.Colors.danger)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(DS.Colors.danger.opacity(0.12))
                        .cornerRadius(DS.Radius.full)
                    }
                }

                // Bar
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        if lowCount > 0 {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(DS.Colors.safe)
                                .frame(width: geo.size.width * CGFloat(lowCount) / CGFloat(total))
                        }
                        if medCount > 0 {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(DS.Colors.warning)
                                .frame(width: geo.size.width * CGFloat(medCount) / CGFloat(total))
                        }
                        if highCount > 0 {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(DS.Colors.danger)
                                .frame(width: geo.size.width * CGFloat(highCount) / CGFloat(total))
                        }
                        if dataStore.scans.isEmpty {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(DS.Colors.divider)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .frame(height: 12)

                HStack(spacing: DS.Spacing.m) {
                    RiskLegendItem(color: DS.Colors.safe, label: "Safe", count: lowCount)
                    RiskLegendItem(color: DS.Colors.warning, label: "Medium", count: medCount)
                    RiskLegendItem(color: DS.Colors.danger, label: "High", count: highCount)
                }
            }
        }
    }
}

struct RiskLegendItem: View {
    let color: Color
    let label: String
    let count: Int

    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text("\(label) (\(count))")
                .font(DS.Typography.caption(11))
                .foregroundColor(DS.Colors.textSecondary)
        }
    }
}

// MARK: - Quick Actions
struct QuickActionsRow: View {
    @Binding var showReports: Bool
    @Binding var showHistory: Bool

    var body: some View {
        HStack(spacing: DS.Spacing.m) {
            QuickActionButton(icon: "clock.fill", label: "History", color: DS.Colors.purple) {
                showHistory = true
            }
            QuickActionButton(icon: "doc.text.fill", label: "Reports", color: DS.Colors.cyanLight) {
                showReports = true
            }
            QuickActionButton(icon: "chart.line.uptrend.xyaxis", label: "Timeline", color: DS.Colors.safe) {
                showHistory = true
            }
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: DS.Spacing.s) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.12))
                    .cornerRadius(DS.Radius.m)
                Text(label)
                    .font(DS.Typography.caption(11))
                    .foregroundColor(DS.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Room Mini Card
struct RoomMiniCard: View {
    let room: Room

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: room.icon)
                .font(.system(size: 22))
                .foregroundColor(DS.Colors.cyan)
                .frame(width: 44, height: 44)
                .background(DS.Colors.cyan.opacity(0.12))
                .cornerRadius(DS.Radius.s)

            Text(room.name)
                .font(DS.Typography.caption())
                .foregroundColor(DS.Colors.textPrimary)

            HStack(spacing: 4) {
                Text("\(room.scanCount)")
                    .font(DS.Typography.caption(11))
                    .foregroundColor(DS.Colors.textMuted)
                Text("scans")
                    .font(DS.Typography.caption(11))
                    .foregroundColor(DS.Colors.textMuted)
            }
        }
        .padding(DS.Spacing.m)
        .background(DS.Colors.card)
        .cornerRadius(DS.Radius.l)
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.l)
                .stroke(DS.Colors.divider, lineWidth: 0.5)
        )
        .frame(width: 110)
    }
}

// MARK: - Empty State Card
struct EmptyStateCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        DSCard {
            VStack(spacing: DS.Spacing.m) {
                Image(systemName: icon)
                    .font(.system(size: 36))
                    .foregroundColor(color.opacity(0.5))
                Text(title)
                    .font(DS.Typography.subheading())
                    .foregroundColor(DS.Colors.textSecondary)
                Text(subtitle)
                    .font(DS.Typography.caption())
                    .foregroundColor(DS.Colors.textMuted)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Spacing.xl)
        }
    }
}
