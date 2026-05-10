import SwiftUI

// MARK: - Design System
struct DS {
    // MARK: Colors
    struct Colors {
        // Backgrounds
        static let bgDeep = Color(hex: "#0A0F1C")
        static let bgPrimary = Color(hex: "#0F172A")
        static let bgSecondary = Color(hex: "#111827")

        // Cards
        static let card = Color(hex: "#1E293B")
        static let cardAlt = Color(hex: "#1F2A44")

        // Dividers
        static let divider = Color(hex: "#334155")
        static let dividerLight = Color.white.opacity(0.05)

        // Accent - Cyan
        static let cyan = Color(hex: "#22D3EE")
        static let cyanActive = Color(hex: "#06B6D4")
        static let cyanLight = Color(hex: "#67E8F9")
        static let cyanGlow = Color(hex: "#22D3EE").opacity(0.4)

        // Accent - Purple
        static let purple = Color(hex: "#6366F1")
        static let purpleLight = Color(hex: "#818CF8")
        static let purpleGlow = Color(hex: "#6366F1").opacity(0.4)

        // Status
        static let safe = Color(hex: "#22C55E")
        static let warning = Color(hex: "#FACC15")
        static let danger = Color(hex: "#EF4444")

        // Surface
        static let wall = Color(hex: "#94A3B8")
        static let crack = Color(hex: "#1E293B")
        static let crackHighlight = Color(hex: "#22D3EE")

        // Text
        static let textPrimary = Color(hex: "#F8FAFC")
        static let textSecondary = Color(hex: "#CBD5E1")
        static let textMuted = Color(hex: "#64748B")

        // Button
        static let btnPrimaryBg = Color(hex: "#22D3EE")
        static let btnPrimaryText = Color(hex: "#0F172A")
        static let btnSecondaryBg = Color(hex: "#1E293B")
        static let btnSecondaryText = Color(hex: "#E2E8F0")
    }

    // MARK: Typography
    struct Typography {
        static func display(_ size: CGFloat = 32) -> Font {
            .system(size: size, weight: .bold, design: .rounded)
        }
        static func heading(_ size: CGFloat = 22) -> Font {
            .system(size: size, weight: .semibold, design: .rounded)
        }
        static func subheading(_ size: CGFloat = 16) -> Font {
            .system(size: size, weight: .medium, design: .rounded)
        }
        static func body(_ size: CGFloat = 14) -> Font {
            .system(size: size, weight: .regular, design: .rounded)
        }
        static func caption(_ size: CGFloat = 12) -> Font {
            .system(size: size, weight: .medium, design: .rounded)
        }
        static func mono(_ size: CGFloat = 13) -> Font {
            .system(size: size, weight: .medium, design: .monospaced)
        }
    }

    // MARK: Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    // MARK: Radius
    struct Radius {
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 20
        static let full: CGFloat = 100
    }
}

// MARK: - Primary Button
struct PrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var isLoading: Bool = false
    var fullWidth: Bool = true

    init(_ title: String, icon: String? = nil, isLoading: Bool = false, fullWidth: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.fullWidth = fullWidth
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.s) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: DS.Colors.btnPrimaryText))
                        .scaleEffect(0.85)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text(title)
                        .font(DS.Typography.subheading())
                }
            }
            .foregroundColor(DS.Colors.btnPrimaryText)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.vertical, 14)
            .padding(.horizontal, fullWidth ? 0 : 24)
            .background(
                LinearGradient(
                    colors: [DS.Colors.cyan, DS.Colors.cyanActive],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(DS.Radius.l)
            .shadow(color: DS.Colors.cyanGlow, radius: 12, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Secondary Button
struct SecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.s) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(DS.Typography.subheading())
            }
            .foregroundColor(DS.Colors.btnSecondaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(DS.Colors.btnSecondaryBg)
            .cornerRadius(DS.Radius.l)
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.l)
                    .stroke(DS.Colors.divider, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Card
struct DSCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = DS.Spacing.l

    init(padding: CGFloat = DS.Spacing.l, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(DS.Colors.card)
            .cornerRadius(DS.Radius.l)
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.l)
                    .stroke(DS.Colors.divider, lineWidth: 0.5)
            )
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        DSCard {
            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color)
                        .padding(8)
                        .background(color.opacity(0.15))
                        .cornerRadius(DS.Radius.s)

                    Spacer()
                }

                Text(value)
                    .font(DS.Typography.display(28))
                    .foregroundColor(DS.Colors.textPrimary)

                Text(title)
                    .font(DS.Typography.caption())
                    .foregroundColor(DS.Colors.textSecondary)

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(DS.Typography.caption(11))
                        .foregroundColor(color)
                }
            }
        }
    }
}

// MARK: - Risk Badge
struct RiskBadge: View {
    let level: RiskLevel

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(level.color)
                .frame(width: 6, height: 6)
            Text(level.rawValue)
                .font(DS.Typography.caption(11))
                .foregroundColor(level.color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(level.color.opacity(0.12))
        .cornerRadius(DS.Radius.full)
    }
}

// MARK: - Scan Row Card
struct ScanRowCard: View {
    let scan: Scan
    let rooms: [Room]

    var roomName: String {
        guard let rid = scan.roomId, let room = rooms.first(where: { $0.id == rid }) else { return "Unknown" }
        return room.name
    }

    var body: some View {
        DSCard(padding: 12) {
            HStack(spacing: DS.Spacing.m) {
                // Placeholder image
                ZStack {
                    RoundedRectangle(cornerRadius: DS.Radius.s)
                        .fill(DS.Colors.bgSecondary)
                        .frame(width: 60, height: 60)
                    if let img = scan.image {
                        Image(uiImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .cornerRadius(DS.Radius.s)
                            .clipped()
                    } else {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 20))
                            .foregroundColor(DS.Colors.cyan.opacity(0.6))
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(scan.crackType.rawValue)
                            .font(DS.Typography.subheading(14))
                            .foregroundColor(DS.Colors.textPrimary)
                        Spacer()
                        RiskBadge(level: scan.riskLevel)
                    }

                    Text(roomName)
                        .font(DS.Typography.caption())
                        .foregroundColor(DS.Colors.textMuted)

                    Text(scan.createdAt, style: .relative)
                        .font(DS.Typography.caption(11))
                        .foregroundColor(DS.Colors.textMuted)
                }
            }
        }
    }
}

// MARK: - Shimmer modifier
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .clear, location: phase - 0.3),
                        .init(color: .white.opacity(0.3), location: phase),
                        .init(color: .clear, location: phase + 0.3)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .animation(
                    Animation.linear(duration: 1.5).repeatForever(autoreverses: false),
                    value: phase
                )
            )
            .onAppear { phase = 1.5 }
            .clipped()
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Tab Item
struct BSTabItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? icon : icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? DS.Colors.cyan : DS.Colors.textMuted)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)

                Text(label)
                    .font(DS.Typography.caption(10))
                    .foregroundColor(isSelected ? DS.Colors.cyan : DS.Colors.textMuted)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
