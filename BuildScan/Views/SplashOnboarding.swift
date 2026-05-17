import SwiftUI
import Combine
import Network

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.7
    @State private var logoOpacity: Double = 0
    @State private var brandOffset: CGFloat = 12
    @State private var brandOpacity: Double = 0
    @State private var statsOpacity: Double = 0
    @State private var cancellables = Set<AnyCancellable>()
    @State private var statsOffset: CGFloat = 16
    @State private var loadingOpacity: Double = 0
    @State private var loadProgress: CGFloat = 0
    @State private var networkMonitor = NWPathMonitor()
    @State private var cornersOpacity: Double = 0
    @State private var scanLineY: CGFloat = -44
    @State private var scanLineOpacity: Double = 0
    @StateObject private var viewModel = BuildScanViewModel()
    @State private var hazardOpacity: Double = 0
    @State private var displayPct: Int = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                // Steel background
                Color(hex: "#0A0A0A").ignoresSafeArea()
                
                GeometryReader { geo in
                    Image("scanningsinfo")
                        .resizable().scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .ignoresSafeArea()
                        .blur(radius: 14)
                        .opacity(0.2)
                }
                .ignoresSafeArea()
                
                SteelTextureView().ignoresSafeArea()
                
                // Hazard stripe — top
                VStack {
                    HazardBarView(horizontal: true)
                        .frame(height: 8)
                        .opacity(hazardOpacity)
                    Spacer()
                }.ignoresSafeArea()
                
                // Hazard stripe — bottom
                VStack {
                    Spacer()
                    HazardBarView(horizontal: false)
                        .frame(height: 60)
                        .opacity(hazardOpacity)
                }.ignoresSafeArea()
                
                NavigationLink(
                    destination: BuildScanWebView().navigationBarHidden(true),
                    isActive: $viewModel.navigateToWeb
                ) { EmptyView() }
                
                NavigationLink(
                    destination: RootView().navigationBarBackButtonHidden(true),
                    isActive: $viewModel.navigateToMain
                ) { EmptyView() }
                
                // Industrial corner brackets
                CornersView().opacity(cornersOpacity)
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Hex logo
                    ZStack {
                        HexagonShape()
                            .fill(Color(hex: "#F5A623"))
                            .frame(width: 100, height: 100)
                        
                        HexagonShape()
                            .fill(Color(hex: "#1A1208"))
                            .frame(width: 92, height: 92)
                        
                        Image(systemName: "cube")
                            .font(.system(size: 40))
                            .foregroundColor(Color(hex: "#F5A623"))
                        
                        // Scan line
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.clear, Color(hex: "#F5A623").opacity(0.8), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 92, height: 2)
                            .offset(y: scanLineY)
                            .opacity(scanLineOpacity)
                            .clipShape(HexagonShape())
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    
                    // Brand
                    VStack(spacing: 4) {
                        HStack(spacing: 0) {
                            Text("BUILD")
                                .font(.system(size: 52, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                                .kerning(6)
                            Text("SCAN")
                                .font(.system(size: 52, weight: .black, design: .rounded))
                                .foregroundColor(Color(hex: "#F5A623"))
                                .kerning(6)
                        }
                        
                        Text("CONSTRUCTION MANAGEMENT")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: "#888888"))
                            .kerning(4)
                    }
                    .offset(y: brandOffset)
                    .opacity(brandOpacity)
                    .padding(.top, 10)
                    
                    // Divider
                    HStack(spacing: 8) {
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [.clear, Color(hex: "#F5A623").opacity(0.4), .clear],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(height: 1)
                        Rectangle()
                            .fill(Color(hex: "#F5A623"))
                            .frame(width: 6, height: 6)
                            .rotationEffect(.degrees(45))
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [.clear, Color(hex: "#F5A623").opacity(0.4), .clear],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                    .opacity(statsOpacity)
                    
                    // Loading bar
                    VStack(spacing: 6) {
                        HStack {
                            Text("INITIALIZING")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Color(hex: "#555555"))
                                .kerning(3)
                            Spacer()
                            Text("\(displayPct)%")
                                .font(.custom("BebasNeue-Regular", size: 14))
                                .foregroundColor(Color(hex: "#F5A623"))
                                .kerning(1)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.06))
                                    .frame(height: 3)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "#C47A0A"), Color(hex: "#F5A623"), Color(hex: "#FFD180")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * loadProgress, height: 3)
                            }
                        }
                        .frame(height: 3)
                    }
                    .padding(.horizontal, 80)
                    .padding(.top, 16)
                    .opacity(loadingOpacity)
                    
                    Spacer()
                }
            }
            .fullScreenCover(isPresented: $viewModel.showPermissionPrompt) {
                BuildScanConsentView(viewModel: viewModel)
            }
            .fullScreenCover(isPresented: $viewModel.showOfflineView) {
                OfflineView()
            }
            .onAppear {
                setupStreams()
                runAnimation()
                setupNetworkMonitoring()
                viewModel.boot()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func runAnimation() {
        // Hazard bars
        withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
            hazardOpacity = 1
        }
        // Logo pop
        withAnimation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.4)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        // Scan line
        withAnimation(.easeInOut(duration: 0.8).delay(1.0)) {
            scanLineY = 44
            scanLineOpacity = 0.9
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            scanLineOpacity = 0
        }
        // Brand text
        withAnimation(.easeOut(duration: 0.4).delay(0.85)) {
            brandOffset = 0
            brandOpacity = 1
        }
        // Corners
        withAnimation(.easeOut(duration: 0.5).delay(0.9)) {
            cornersOpacity = 1
        }
        // Stats
        withAnimation(.easeOut(duration: 0.5).delay(1.2)) {
            statsOpacity = 1
            statsOffset = 0
        }
        // Loading bar
        withAnimation(.easeOut(duration: 0.3).delay(1.5)) {
            loadingOpacity = 1
        }
        withAnimation(.easeInOut(duration: 20.0).delay(1.8)) {
            loadProgress = 1.0
        }
        // Percent counter
        animatePct()
    }
    
    private func setupStreams() {
        NotificationCenter.default.publisher(for: Notification.Name("ConversionDataReceived"))
            .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
            .sink { data in
                viewModel.ingestAttribution(data)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name("deeplink_values"))
            .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
            .sink { data in
                viewModel.ingestDeeplinks(data)
            }
            .store(in: &cancellables)
    }
    
    private func animatePct() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            let total = 288 // ~36 ticks over 2s
            for i in 0...total {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * (16.0 / Double(total))) {
                    let eased = Double(i) / Double(total)
                    displayPct = Int(eased * eased * 100)
                }
            }
        }
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { path in
            Task { @MainActor in
                viewModel.networkConnectivityChanged(path.status == .satisfied)
            }
        }
        networkMonitor.start(queue: .global(qos: .background))
    }
    
}

struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        let cx = rect.midX, cy = rect.midY
        let r = min(w, h) / 2
        for i in 0..<6 {
            let angle = CGFloat(i) * .pi / 3 - .pi / 2
            let pt = CGPoint(x: cx + r * cos(angle), y: cy + r * sin(angle))
            i == 0 ? path.move(to: pt) : path.addLine(to: pt)
        }
        path.closeSubpath()
        return path
    }
}

struct StatCell: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.custom("BebasNeue-Regular", size: 26))
                .foregroundColor(Color(hex: "#F5A623"))
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(Color(hex: "#555555"))
                .kerning(2)
        }
        .frame(minWidth: 80)
        .padding(.vertical, 12)
        .background(Color(hex: "#F5A623").opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color(hex: "#F5A623").opacity(0.15), lineWidth: 1)
        )
    }
}

struct SteelTextureView: View {
    var body: some View {
        Canvas { context, size in
            // Vertical thin lines — steel plate texture
            var x: CGFloat = 0
            while x < size.width {
                let path = Path { p in
                    p.move(to: CGPoint(x: x, y: 0))
                    p.addLine(to: CGPoint(x: x, y: size.height))
                }
                context.stroke(path, with: .color(.white.opacity(0.012)), lineWidth: 0.5)
                x += 4
            }
            var y: CGFloat = 0
            while y < size.height {
                let path = Path { p in
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: size.width, y: y))
                }
                context.stroke(path, with: .color(.white.opacity(0.008)), lineWidth: 0.5)
                y += 4
            }
        }
    }
}

struct HazardBarView: View {
    let horizontal: Bool

    var body: some View {
        Canvas { context, size in
            let stripeWidth: CGFloat = 28
            var offset: CGFloat = -stripeWidth
            while offset < size.width + size.height {
                let path = Path { p in
                    p.move(to: CGPoint(x: offset, y: 0))
                    p.addLine(to: CGPoint(x: offset + stripeWidth / 2, y: 0))
                    p.addLine(to: CGPoint(x: offset + stripeWidth / 2 - size.height, y: size.height))
                    p.addLine(to: CGPoint(x: offset - size.height, y: size.height))
                    p.closeSubpath()
                }
                context.fill(path, with: .color(Color(hex: "#F5A623").opacity(0.7)))
                offset += stripeWidth
            }
            if !horizontal {
                // Fade overlay
                let grad = Gradient(colors: [Color(hex: "#0A0A0A"), .clear])
                let gradRect = CGRect(origin: .zero, size: size)
                context.fill(Path(gradRect), with: .linearGradient(
                    grad,
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: 0, y: size.height)
                ))
            }
        }
    }
}

struct CornersView: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                let margin: CGFloat = 16
                let size: CGFloat = 24
                let color = Color(hex: "#F5A623")
                let lw: CGFloat = 2

                // TL
                Path { p in
                    p.move(to: CGPoint(x: margin, y: margin + size))
                    p.addLine(to: CGPoint(x: margin, y: margin))
                    p.addLine(to: CGPoint(x: margin + size, y: margin))
                }.stroke(color, lineWidth: lw)

                // TR
                Path { p in
                    p.move(to: CGPoint(x: geo.size.width - margin - size, y: margin))
                    p.addLine(to: CGPoint(x: geo.size.width - margin, y: margin))
                    p.addLine(to: CGPoint(x: geo.size.width - margin, y: margin + size))
                }.stroke(color, lineWidth: lw)

                // BL
                Path { p in
                    p.move(to: CGPoint(x: margin, y: geo.size.height - 70 - size))
                    p.addLine(to: CGPoint(x: margin, y: geo.size.height - 70))
                    p.addLine(to: CGPoint(x: margin + size, y: geo.size.height - 70))
                }.stroke(color, lineWidth: lw)

                // BR
                Path { p in
                    p.move(to: CGPoint(x: geo.size.width - margin - size, y: geo.size.height - 70))
                    p.addLine(to: CGPoint(x: geo.size.width - margin, y: geo.size.height - 70))
                    p.addLine(to: CGPoint(x: geo.size.width - margin, y: geo.size.height - 70 - size))
                }.stroke(color, lineWidth: lw)
            }
        }
    }
}


struct CrackIconView: View {
    var body: some View {
        ZStack {
            // Wall background
            RoundedRectangle(cornerRadius: 4)
                .fill(DS.Colors.wall.opacity(0.2))

            // Crack paths
            Path { path in
                path.move(to: CGPoint(x: 30, y: 10))
                path.addLine(to: CGPoint(x: 24, y: 25))
                path.addLine(to: CGPoint(x: 32, y: 32))
                path.addLine(to: CGPoint(x: 20, y: 50))
            }
            .stroke(DS.Colors.cyan, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

            // Highlight dots
            Circle().fill(DS.Colors.cyanLight).frame(width: 4, height: 4).offset(x: -6, y: -4)
            Circle().fill(DS.Colors.cyanLight).frame(width: 3, height: 3).offset(x: 2, y: 2)
        }
    }
}

struct ParticleDot: View {
    let index: Int
    @State private var yOffset: CGFloat = 0
    @State private var opacity: Double = Double.random(in: 0.3...0.8)

    var x: CGFloat { CGFloat([-120, -80, -40, 0, 40, 80, 120, -100, 100, -60, 60, -20][index % 12]) }
    var y: CGFloat { CGFloat([-200, -150, -180, -160, -140, -170, -200, 150, 180, 160, 140, 200][index % 12]) }
    var size: CGFloat { CGFloat([3, 4, 2, 5, 3, 4, 2, 3, 5, 4, 2, 3][index % 12]) }

    var body: some View {
        Circle()
            .fill(DS.Colors.cyan)
            .frame(width: size, height: size)
            .offset(x: x, y: y + yOffset)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: Double.random(in: 2...4))
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.15)
                ) {
                    yOffset = CGFloat.random(in: -20...20)
                    opacity = Double.random(in: 0.1...0.6)
                }
            }
    }
}

struct GridBackgroundView: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 40
            context.stroke(
                gridPath(size: size, spacing: spacing),
                with: .color(DS.Colors.cyan.opacity(0.08)),
                lineWidth: 0.5
            )
        }
        .ignoresSafeArea()
    }

    private func gridPath(size: CGSize, spacing: CGFloat) -> Path {
        var path = Path()
        var x: CGFloat = 0
        while x <= size.width {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
            x += spacing
        }
        var y: CGFloat = 0
        while y <= size.height {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            y += spacing
        }
        return path
    }
}

// MARK: - Welcome Screen
struct WelcomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showLogin = false
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var contentOffset: CGFloat = 40
    @State private var contentOpacity: Double = 0

    var body: some View {
        ZStack {
            DS.Colors.bgPrimary.ignoresSafeArea()
            GridBackgroundView().opacity(0.15)

            VStack(spacing: 0) {
                Spacer()

                // Hero
                VStack(spacing: DS.Spacing.xl) {
                    // Animated icon
                    ZStack {
                        Circle()
                            .fill(DS.Colors.cyanGlow)
                            .frame(width: 140, height: 140)
                            .blur(radius: 25)

                        ZStack {
                            RoundedRectangle(cornerRadius: 32)
                                .fill(
                                    LinearGradient(
                                        colors: [DS.Colors.card, DS.Colors.bgSecondary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 110, height: 110)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 32)
                                        .stroke(DS.Colors.cyan.opacity(0.5), lineWidth: 1)
                                )

                            CrackIconView()
                                .frame(width: 70, height: 70)
                        }
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                    VStack(spacing: DS.Spacing.m) {
                        Text("Build Scan")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(DS.Colors.textPrimary)

                        Text("Professional wall crack analysis\nat your fingertips")
                            .font(DS.Typography.subheading(16))
                            .foregroundColor(DS.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                }

                Spacer()

                // Feature highlights
                VStack(spacing: DS.Spacing.m) {
                    FeatureRow(icon: "camera.viewfinder", text: "Scan & detect wall cracks", color: DS.Colors.cyan)
                    FeatureRow(icon: "waveform.path.ecg", text: "AI-powered risk analysis", color: DS.Colors.purple)
                    FeatureRow(icon: "chart.xyaxis.line", text: "Track changes over time", color: DS.Colors.safe)
                }
                .padding(.horizontal, DS.Spacing.l)

                Spacer()

                // Buttons
                VStack(spacing: DS.Spacing.m) {
                    PrimaryButton("Get Started", icon: "arrow.right") {
                        showLogin = true
                    }

                    SecondaryButton("Log In") {
                        showLogin = true
                    }
                }
                .padding(.horizontal, DS.Spacing.l)
                .padding(.bottom, 40)
            }
            .offset(y: contentOffset)
            .opacity(contentOpacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                contentOffset = 0
                contentOpacity = 1.0
            }
        }
        .fullScreenCover(isPresented: $showLogin) {
            LoginView()
                .environmentObject(appState)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: DS.Spacing.m) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.12))
                .cornerRadius(DS.Radius.s)

            Text(text)
                .font(DS.Typography.subheading(14))
                .foregroundColor(DS.Colors.textSecondary)

            Spacer()

            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(color)
        }
    }
}

// MARK: - Onboarding
struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage: Int = 0
    @State private var dragOffset: CGFloat = 0

    let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Scan Cracks Easily",
            subtitle: "Point your camera at any wall surface and detect cracks instantly with our smart scanning technology.",
            illustration: "onboarding_scan",
            icon: "camera.viewfinder",
            accent: DS.Colors.cyan
        ),
        OnboardingPage(
            title: "Analyze Wall Damage",
            subtitle: "Our AI engine classifies crack types, measures severity, and provides detailed structural analysis.",
            illustration: "onboarding_analyze",
            icon: "waveform.path.ecg",
            accent: DS.Colors.purple
        ),
        OnboardingPage(
            title: "Fix Problems Early",
            subtitle: "Get personalized repair recommendations before minor cracks become major structural issues.",
            illustration: "onboarding_fix",
            icon: "wrench.and.screwdriver.fill",
            accent: DS.Colors.safe
        )
    ]

    var body: some View {
        ZStack {
            DS.Colors.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        finishOnboarding()
                    }
                    .font(DS.Typography.subheading(14))
                    .foregroundColor(DS.Colors.textMuted)
                    .padding()
                }

                // Pages
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { idx in
                        OnboardingPageView(page: pages[idx])
                            .tag(idx)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentPage)

                // Dots and nav
                VStack(spacing: DS.Spacing.xl) {
                    // Dots
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { i in
                            Capsule()
                                .fill(i == currentPage ? pages[currentPage].accent : DS.Colors.divider)
                                .frame(width: i == currentPage ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                        }
                    }

                    if currentPage < pages.count - 1 {
                        PrimaryButton("Next", icon: "arrow.right") {
                            withAnimation { currentPage += 1 }
                        }
                        .padding(.horizontal, DS.Spacing.l)
                    } else {
                        PrimaryButton("Start Scanning", icon: "camera.viewfinder") {
                            finishOnboarding()
                        }
                        .padding(.horizontal, DS.Spacing.l)
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }

    private func finishOnboarding() {
        appState.hasCompletedOnboarding = true
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let illustration: String
    let icon: String
    let accent: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var illustrationScale: CGFloat = 0.8
    @State private var illustrationOpacity: Double = 0
    @State private var textOpacity: Double = 0

    var body: some View {
        VStack(spacing: DS.Spacing.xxl) {
            // Illustration
            ZStack {
                Circle()
                    .fill(page.accent.opacity(0.08))
                    .frame(width: 280, height: 280)

                Circle()
                    .fill(page.accent.opacity(0.05))
                    .frame(width: 200, height: 200)

                // Main illustration
                ZStack {
                    RoundedRectangle(cornerRadius: 32)
                        .fill(DS.Colors.card)
                        .frame(width: 160, height: 160)
                        .overlay(
                            RoundedRectangle(cornerRadius: 32)
                                .stroke(page.accent.opacity(0.4), lineWidth: 1.5)
                        )
                        .shadow(color: page.accent.opacity(0.2), radius: 20)

                    Image(systemName: page.icon)
                        .font(.system(size: 60, weight: .light))
                        .foregroundColor(page.accent)

                    // Floating particles
                    ForEach(0..<6, id: \.self) { i in
                        OnboardingParticle(index: i, color: page.accent)
                    }
                }
            }
            .scaleEffect(illustrationScale)
            .opacity(illustrationOpacity)

            // Text
            VStack(spacing: DS.Spacing.m) {
                Text(page.title)
                    .font(DS.Typography.display(30))
                    .foregroundColor(DS.Colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(DS.Typography.body(16))
                    .foregroundColor(DS.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, DS.Spacing.xl)
            }
            .opacity(textOpacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                illustrationScale = 1.0
                illustrationOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                textOpacity = 1.0
            }
        }
    }
}

struct OnboardingParticle: View {
    let index: Int
    let color: Color
    @State private var offset: CGFloat = 0

    var xPos: CGFloat { [90, -90, 100, -100, 70, -70][index % 6] }
    var yPos: CGFloat { [-80, -80, 0, 0, 80, 80][index % 6] }

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 6, height: 6)
            .offset(x: xPos, y: yPos + offset)
            .opacity(0.6)
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: Double.random(in: 1.5...3.0))
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.2)
                ) {
                    offset = CGFloat.random(in: -10...10)
                }
            }
    }
}
