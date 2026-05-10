import SwiftUI

// MARK: - Splash Screen
struct SplashView: View {
    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0
    @State private var glowRadius: CGFloat = 0
    @State private var particleOpacity: Double = 0
    @State private var textOffset: CGFloat = 30
    @State private var textOpacity: Double = 0
    @State private var scanLineOffset: CGFloat = -100
    @State private var scanLineOpacity: Double = 0
    var onComplete: () -> Void

    var body: some View {
        ZStack {
            DS.Colors.bgPrimary.ignoresSafeArea()

            // Background grid
            GridBackgroundView()
                .opacity(0.3)

            // Particles
            ForEach(0..<12, id: \.self) { i in
                ParticleDot(index: i)
                    .opacity(particleOpacity)
            }

            VStack(spacing: DS.Spacing.xl) {
                // Logo
                ZStack {
                    // Glow
                    Circle()
                        .fill(DS.Colors.cyanGlow)
                        .frame(width: 120, height: 120)
                        .blur(radius: glowRadius)

                    // Icon bg
                    ZStack {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(
                                LinearGradient(
                                    colors: [DS.Colors.card, DS.Colors.bgSecondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 28)
                                    .stroke(DS.Colors.cyan.opacity(0.6), lineWidth: 1.5)
                            )

                        // Crack icon
                        CrackIconView()
                            .frame(width: 60, height: 60)
                    }

                    // Scan line
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, DS.Colors.cyan, .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 80, height: 2)
                        .offset(y: scanLineOffset)
                        .opacity(scanLineOpacity)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                }
                .scaleEffect(scale)
                .opacity(opacity)

                VStack(spacing: 8) {
                    Text("Build Scan")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(DS.Colors.textPrimary)

                    Text("Scan your walls")
                        .font(DS.Typography.subheading())
                        .foregroundColor(DS.Colors.cyan)
                        .tracking(3)
                        .textCase(.uppercase)
                }
                .offset(y: textOffset)
                .opacity(textOpacity)
            }
        }
        .onAppear { runAnimation() }
    }

    private func runAnimation() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
            scale = 1.0
            opacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.8).delay(0.4)) {
            glowRadius = 30
            particleOpacity = 0.8
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.6)) {
            textOffset = 0
            textOpacity = 1.0
        }
        withAnimation(.easeInOut(duration: 0.8).delay(0.8)) {
            scanLineOffset = 100
            scanLineOpacity = 0.9
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            onComplete()
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
