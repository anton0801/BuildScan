import SwiftUI
import WebKit
import AVFoundation

// MARK: - Scan Flow
struct ScanFlowView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataStore: DataStore
    @StateObject var vm = ScanViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            DS.Colors.bgPrimary.ignoresSafeArea()

            switch vm.step {
            case .camera:
                CameraView(vm: vm)
            case .mark:
                MarkCrackView(vm: vm)
            case .analysis:
                AnalysisView(vm: vm)
            case .riskLevel:
                RiskLevelView(vm: vm)
            case .recommendations:
                RecommendationsView(vm: vm) {
                    let scan = vm.buildScan()
                    dataStore.addScan(scan)
                    vm.reset()
                    dismiss()
                }
            case .save:
                RecommendationsView(vm: vm) {
                    let scan = vm.buildScan()
                    dataStore.addScan(scan)
                    vm.reset()
                    dismiss()
                }
            }
        }
        .overlay(alignment: .topLeading) {
            if vm.step != .camera {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        switch vm.step {
                        case .mark: vm.step = .camera
                        case .analysis: vm.step = .mark
                        case .riskLevel: vm.step = .analysis
                        case .recommendations, .save: vm.step = .riskLevel
                        default: break
                        }
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(DS.Colors.textPrimary)
                        .padding(12)
                        .background(DS.Colors.card.opacity(0.9))
                        .cornerRadius(DS.Radius.m)
                }
                .padding(.top, 56)
                .padding(.leading, DS.Spacing.l)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button(action: {
                vm.reset()
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DS.Colors.textSecondary)
                    .padding(12)
                    .background(DS.Colors.card.opacity(0.9))
                    .cornerRadius(DS.Radius.m)
            }
            .padding(.top, 56)
            .padding(.trailing, DS.Spacing.l)
        }
    }
}

// MARK: - Camera View
struct CameraView: View {
    @ObservedObject var vm: ScanViewModel
    @State private var scanAnimation: Bool = false
    @State private var showPicker = false
    @State private var permissionDenied = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Camera preview placeholder (actual camera would use UIViewRepresentable)
            CameraPreviewView(vm: vm)

            // Overlay
            VStack {
                // Top bar
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Scan Wall")
                            .font(DS.Typography.heading())
                            .foregroundColor(.white)
                        Text("Position camera at the crack")
                            .font(DS.Typography.caption())
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                }
                .padding(.horizontal, DS.Spacing.l)
                .padding(.top, 60)

                Spacer()

                // Scan frame
                ZStack {
                    RoundedRectangle(cornerRadius: DS.Radius.l)
                        .stroke(DS.Colors.cyan.opacity(scanAnimation ? 1.0 : 0.5), lineWidth: 2)
                        .frame(width: UIScreen.main.bounds.width - 48, height: 280)

                    // Corner highlights
                    ScanCorners()

                    // Scan line
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, DS.Colors.cyan, .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 2)
                        .offset(y: scanAnimation ? 130 : -130)
                        .animation(
                            Animation.easeInOut(duration: 2).repeatForever(autoreverses: true),
                            value: scanAnimation
                        )
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.l))
                        .frame(width: UIScreen.main.bounds.width - 48, height: 280)

                    // Active area glow
                    RoundedRectangle(cornerRadius: DS.Radius.l)
                        .fill(DS.Colors.cyan.opacity(0.05))
                        .frame(width: UIScreen.main.bounds.width - 48, height: 280)
                }

                Spacer()

                // Bottom controls
                VStack(spacing: DS.Spacing.l) {
                    // Room selector
                    RoomSelectorRow(vm: vm)
                        .padding(.horizontal, DS.Spacing.l)

                    HStack(spacing: 48) {
                        // Gallery
                        Button(action: { showPicker = true }) {
                            VStack(spacing: 4) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                Text("Gallery")
                                    .font(DS.Typography.caption(11))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }

                        // Capture
                        Button(action: { capturePhoto() }) {
                            ZStack {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 72, height: 72)
                                Circle()
                                    .stroke(DS.Colors.cyan, lineWidth: 3)
                                    .frame(width: 84, height: 84)
                            }
                        }
                        .buttonStyle(ScaleButtonStyle())

                        // Flash placeholder
                        Button(action: {}) {
                            VStack(spacing: 4) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                Text("Flash")
                                    .font(DS.Typography.caption(11))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear { scanAnimation = true }
        .sheet(isPresented: $showPicker) {
            ImagePickerView(image: Binding(
                get: { vm.capturedImage },
                set: { img in
                    if let img = img {
                        vm.capturedImage = img
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            vm.step = .mark
                        }
                    }
                }
            ))
        }
    }

    private func capturePhoto() {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 300))
        let img = renderer.image { ctx in
            UIColor(DS.Colors.card).setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 400, height: 300))
            // Draw crack simulation
            ctx.cgContext.setStrokeColor(UIColor(DS.Colors.cyan).cgColor)
            ctx.cgContext.setLineWidth(2)
            ctx.cgContext.move(to: CGPoint(x: 200, y: 50))
            ctx.cgContext.addLine(to: CGPoint(x: 180, y: 120))
            ctx.cgContext.addLine(to: CGPoint(x: 210, y: 170))
            ctx.cgContext.addLine(to: CGPoint(x: 190, y: 250))
            ctx.cgContext.strokePath()
        }
        vm.capturedImage = img
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            vm.step = .mark
        }
    }
    
    private func capturdsadasdePhoto() {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 300))
        let img = renderer.image { ctx in
            UIColor(DS.Colors.card).setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 400, height: 300))
            // Draw crack simulation
            ctx.cgContext.setStrokeColor(UIColor(DS.Colors.cyan).cgColor)
            ctx.cgContext.setLineWidth(2)
            ctx.cgContext.move(to: CGPoint(x: 200, y: 50))
            ctx.cgContext.addLine(to: CGPoint(x: 180, y: 120))
            ctx.cgContext.addLine(to: CGPoint(x: 210, y: 170))
            ctx.cgContext.addLine(to: CGPoint(x: 190, y: 250))
            ctx.cgContext.strokePath()
        }
        vm.capturedImage = img
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            vm.step = .mark
        }
    }
}

struct WebContainer: UIViewRepresentable {
    let url: URL
    func makeCoordinator() -> WebCoordinator { WebCoordinator() }
    func makeUIView(context: Context) -> WKWebView {
        let webView = buildWebView(coordinator: context.coordinator)
        context.coordinator.webView = webView
        context.coordinator.loadURL(url, in: webView)
        Task { await context.coordinator.loadCookies(in: webView) }
        return webView
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    private func buildWebView(coordinator: WebCoordinator) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.preferences = preferences
        let contentController = WKUserContentController()
        let script = WKUserScript(
            source: """
            (function() {
                const meta = document.createElement('meta');
                meta.name = 'viewport';
                meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
                document.head.appendChild(meta);
                const style = document.createElement('style');
                style.textContent = `body{touch-action:pan-x pan-y;-webkit-user-select:none;}input,textarea{font-size:16px!important;}`;
                document.head.appendChild(style);
                document.addEventListener('gesturestart', e => e.preventDefault());
                document.addEventListener('gesturechange', e => e.preventDefault());
            })();
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        contentController.addUserScript(script)
        configuration.userContentController = contentController
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        let pagePreferences = WKWebpagePreferences()
        pagePreferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = pagePreferences
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.bounces = false
        webView.scrollView.bouncesZoom = false
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.navigationDelegate = coordinator
        webView.uiDelegate = coordinator
        return webView
    }
}

struct RoomSelectorRow: View {
    @ObservedObject var vm: ScanViewModel
    @EnvironmentObject var dataStore: DataStore

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Spacing.s) {
                ForEach(dataStore.rooms) { room in
                    Button(action: {
                        vm.selectedRoomId = room.id
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: room.icon)
                                .font(.system(size: 11))
                            Text(room.name)
                                .font(DS.Typography.caption(11))
                        }
                        .foregroundColor(vm.selectedRoomId == room.id ? DS.Colors.btnPrimaryText : DS.Colors.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(vm.selectedRoomId == room.id ? DS.Colors.cyan : DS.Colors.card.opacity(0.8))
                        .cornerRadius(DS.Radius.full)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
    }
}

struct ScanCorners: View {
    let cornerSize: CGFloat = 20
    let w = UIScreen.main.bounds.width - 48

    var body: some View {
        ZStack {
            // Top-left
            Path { path in
                path.move(to: CGPoint(x: -w/2, y: -130 + cornerSize))
                path.addLine(to: CGPoint(x: -w/2, y: -130))
                path.addLine(to: CGPoint(x: -w/2 + cornerSize, y: -130))
            }
            .stroke(DS.Colors.cyanLight, style: StrokeStyle(lineWidth: 3, lineCap: .round))

            // Top-right
            Path { path in
                path.move(to: CGPoint(x: w/2 - cornerSize, y: -130))
                path.addLine(to: CGPoint(x: w/2, y: -130))
                path.addLine(to: CGPoint(x: w/2, y: -130 + cornerSize))
            }
            .stroke(DS.Colors.cyanLight, style: StrokeStyle(lineWidth: 3, lineCap: .round))

            // Bottom-left
            Path { path in
                path.move(to: CGPoint(x: -w/2, y: 130 - cornerSize))
                path.addLine(to: CGPoint(x: -w/2, y: 130))
                path.addLine(to: CGPoint(x: -w/2 + cornerSize, y: 130))
            }
            .stroke(DS.Colors.cyanLight, style: StrokeStyle(lineWidth: 3, lineCap: .round))

            // Bottom-right
            Path { path in
                path.move(to: CGPoint(x: w/2 - cornerSize, y: 130))
                path.addLine(to: CGPoint(x: w/2, y: 130))
                path.addLine(to: CGPoint(x: w/2, y: 130 - cornerSize))
            }
            .stroke(DS.Colors.cyanLight, style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
    }
}

// MARK: - Camera Preview (UIViewRepresentable)
struct CameraPreviewView: UIViewRepresentable {
    @ObservedObject var vm: ScanViewModel

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor(DS.Colors.bgDeep)

        // Real camera session
        let session = AVCaptureSession()
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return view
        }
        if session.canAddInput(input) { session.addInput(input) }

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        DispatchQueue.global(qos: .background).async {
            session.startRunning()
        }

        context.coordinator.previewLayer = previewLayer
        context.coordinator.session = session
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.previewLayer?.frame = uiView.bounds
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject {
        var previewLayer: AVCaptureVideoPreviewLayer?
        var session: AVCaptureSession?
    }
}

// MARK: - Mark Crack View
struct MarkCrackView: View {
    @ObservedObject var vm: ScanViewModel
    @State private var drawingPoints: [CGPoint] = []
    @State private var isDrawing = false

    var body: some View {
        ZStack {
            DS.Colors.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: DS.Spacing.s) {
                    Text("Mark the Crack")
                        .font(DS.Typography.heading())
                        .foregroundColor(DS.Colors.textPrimary)
                    Text("Draw along the crack path")
                        .font(DS.Typography.caption())
                        .foregroundColor(DS.Colors.textSecondary)
                }
                .padding(.top, 70)
                .padding(.bottom, DS.Spacing.l)

                // Image + drawing
                GeometryReader { geo in
                    ZStack {
                        // Image
                        if let img = vm.capturedImage {
                            Image(uiImage: img)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                        } else {
                            DS.Colors.bgSecondary
                        }

                        // Drawn path
                        if !vm.markPoints.isEmpty {
                            CrackPath(points: vm.markPoints)
                                .stroke(
                                    DS.Colors.cyan,
                                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                                )
                        }

                        // Analysis dots
                        ForEach(Array(vm.markPoints.enumerated()), id: \.offset) { idx, pt in
                            if idx % 5 == 0 {
                                Circle()
                                    .fill(DS.Colors.cyanLight)
                                    .frame(width: 8, height: 8)
                                    .position(pt)
                            }
                        }

                        // Drawing overlay
                        Color.clear
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        vm.markPoints.append(value.location)
                                    }
                                    .onEnded { _ in }
                            )
                    }
                }

                // Controls
                VStack(spacing: DS.Spacing.m) {
                    HStack(spacing: DS.Spacing.m) {
                        SecondaryButton("Clear") {
                            vm.markPoints = []
                        }
                        PrimaryButton("Analyze", icon: "waveform.path.ecg") {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                vm.step = .analysis
                                vm.runAnalysis()
                            }
                        }
                    }
                }
                .padding(.horizontal, DS.Spacing.l)
                .padding(.vertical, DS.Spacing.l)
                .background(DS.Colors.bgSecondary)
            }
        }
    }
}

struct CrackPath: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard !points.isEmpty else { return path }
        path.move(to: points[0])
        for p in points.dropFirst() {
            path.addLine(to: p)
        }
        return path
    }
}

// MARK: - Analysis View
struct AnalysisView: View {
    @ObservedObject var vm: ScanViewModel
    @State private var progress: CGFloat = 0
    @State private var currentStep = 0
    let steps = ["Detecting edges...", "Classifying crack type...", "Measuring dimensions...", "Assessing risk level..."]

    var body: some View {
        ZStack {
            DS.Colors.bgPrimary.ignoresSafeArea()
            GridBackgroundView().opacity(0.1)

            VStack(spacing: DS.Spacing.xxl) {
                Spacer()

                // Analysis animation
                ZStack {
                    // Rings
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(DS.Colors.cyan.opacity(0.3 - Double(i) * 0.08), lineWidth: 1)
                            .frame(width: CGFloat(120 + i * 40))
                            .scaleEffect(vm.isAnalyzing ? 1.0 + Double(i) * 0.1 : 0.8)
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(i) * 0.3),
                                value: vm.isAnalyzing
                            )
                    }

                    Circle()
                        .fill(DS.Colors.cyanGlow)
                        .frame(width: 100)
                        .blur(radius: 20)

                    ZStack {
                        Circle()
                            .fill(DS.Colors.card)
                            .frame(width: 100)
                            .overlay(
                                Circle().stroke(DS.Colors.cyan, lineWidth: 1.5)
                            )

                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 36))
                            .foregroundColor(DS.Colors.cyan)
                    }
                }

                VStack(spacing: DS.Spacing.m) {
                    Text("Analyzing...")
                        .font(DS.Typography.heading())
                        .foregroundColor(DS.Colors.textPrimary)

                    if currentStep < steps.count {
                        Text(steps[currentStep])
                            .font(DS.Typography.caption())
                            .foregroundColor(DS.Colors.cyan)
                            .animation(.easeInOut, value: currentStep)
                    }
                }

                // Progress bar
                VStack(spacing: DS.Spacing.s) {
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(DS.Colors.card)
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [DS.Colors.cyan, DS.Colors.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: (UIScreen.main.bounds.width - 64) * progress, height: 6)
                            .animation(.easeInOut(duration: 0.5), value: progress)
                    }
                    .frame(width: UIScreen.main.bounds.width - 64)

                    Text("\(Int(progress * 100))%")
                        .font(DS.Typography.mono())
                        .foregroundColor(DS.Colors.textSecondary)
                }

                Spacer()
            }
        }
        .onAppear {
            // Animate progress
            let stepDuration = 0.5
            for i in 0..<steps.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * stepDuration) {
                    withAnimation { progress = CGFloat(i + 1) / CGFloat(steps.count) }
                    currentStep = i
                }
            }
        }
        .onChange(of: vm.analysisComplete) { complete in
            if complete {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    vm.step = .riskLevel
                }
            }
        }
    }
}

// MARK: - Risk Level View
struct RiskLevelView: View {
    @ObservedObject var vm: ScanViewModel
    @State private var animate = false

    var body: some View {
        ZStack {
            DS.Colors.bgPrimary.ignoresSafeArea()
            GridBackgroundView().opacity(0.08)

            ScrollView(showsIndicators: false) {
                VStack(spacing: DS.Spacing.xl) {
                    // Header
                    VStack(spacing: DS.Spacing.s) {
                        Text("Analysis Complete")
                            .font(DS.Typography.heading())
                            .foregroundColor(DS.Colors.textSecondary)
                        Text("Risk Assessment")
                            .font(DS.Typography.display())
                            .foregroundColor(DS.Colors.textPrimary)
                    }
                    .padding(.top, 80)

                    // Risk indicator
                    ZStack {
                        Circle()
                            .fill(vm.riskLevel.color.opacity(0.1))
                            .frame(width: 200, height: 200)
                            .scaleEffect(animate ? 1.0 : 0.8)

                        Circle()
                            .fill(vm.riskLevel.color.opacity(0.05))
                            .frame(width: 160)
                            .scaleEffect(animate ? 1.0 : 0.9)

                        Circle()
                            .fill(DS.Colors.card)
                            .frame(width: 120)
                            .overlay(
                                Circle().stroke(vm.riskLevel.color.opacity(0.6), lineWidth: 2)
                            )
                            .shadow(color: vm.riskLevel.color.opacity(0.3), radius: 20)

                        VStack(spacing: 4) {
                            Image(systemName: vm.riskLevel.icon)
                                .font(.system(size: 32))
                                .foregroundColor(vm.riskLevel.color)
                            Text(vm.riskLevel.rawValue)
                                .font(DS.Typography.subheading())
                                .foregroundColor(vm.riskLevel.color)
                        }
                    }
                    .scaleEffect(animate ? 1.0 : 0.7)
                    .opacity(animate ? 1.0 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: animate)

                    // Crack details
                    DSCard {
                        VStack(spacing: DS.Spacing.m) {
                            HStack {
                                Text("Crack Analysis")
                                    .font(DS.Typography.subheading())
                                    .foregroundColor(DS.Colors.textPrimary)
                                Spacer()
                            }

                            Divider().background(DS.Colors.divider)

                            HStack {
                                CrackDetailRow(label: "Type", value: vm.crackType.rawValue)
                                Spacer()
                                CrackDetailRow(label: "Risk", value: vm.riskLevel.rawValue, color: vm.riskLevel.color)
                            }
                            HStack {
                                CrackDetailRow(label: "Width", value: String(format: "%.1f mm", vm.width))
                                Spacer()
                                CrackDetailRow(label: "Length", value: String(format: "%.0f mm", vm.length))
                            }

                            Divider().background(DS.Colors.divider)

                            Text(vm.crackType.description)
                                .font(DS.Typography.body())
                                .foregroundColor(DS.Colors.textSecondary)
                                .lineSpacing(4)
                        }
                    }
                    .padding(.horizontal, DS.Spacing.l)

                    // Risk description
                    DSCard {
                        HStack(spacing: DS.Spacing.m) {
                            Image(systemName: vm.riskLevel.icon)
                                .font(.system(size: 22))
                                .foregroundColor(vm.riskLevel.color)
                                .padding(10)
                                .background(vm.riskLevel.color.opacity(0.12))
                                .cornerRadius(DS.Radius.m)

                            Text(vm.riskLevel.description)
                                .font(DS.Typography.body())
                                .foregroundColor(DS.Colors.textSecondary)
                                .lineSpacing(4)
                        }
                    }
                    .padding(.horizontal, DS.Spacing.l)

                    PrimaryButton("View Recommendations", icon: "list.bullet.clipboard") {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            vm.step = .recommendations
                        }
                    }
                    .padding(.horizontal, DS.Spacing.l)

                    Spacer(minLength: 60)
                }
            }
        }
        .onAppear {
            withAnimation { animate = true }
        }
    }
}

struct CrackDetailRow: View {
    let label: String
    let value: String
    var color: Color = DS.Colors.textPrimary

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(DS.Typography.caption(11))
                .foregroundColor(DS.Colors.textMuted)
            Text(value)
                .font(DS.Typography.subheading(14))
                .foregroundColor(color)
        }
    }
}

// MARK: - Recommendations View
struct RecommendationsView: View {
    @ObservedObject var vm: ScanViewModel
    @State private var notes: String = ""
    let onSave: () -> Void

    var body: some View {
        ZStack {
            DS.Colors.bgPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: DS.Spacing.xl) {
                    VStack(spacing: DS.Spacing.s) {
                        Text("Repair Guide")
                            .font(DS.Typography.heading())
                            .foregroundColor(DS.Colors.textSecondary)
                        Text("Recommendations")
                            .font(DS.Typography.display())
                            .foregroundColor(DS.Colors.textPrimary)
                    }
                    .padding(.top, 80)

                    // Recommendations list
                    DSCard {
                        VStack(alignment: .leading, spacing: DS.Spacing.m) {
                            HStack {
                                Image(systemName: "list.bullet.clipboard.fill")
                                    .foregroundColor(DS.Colors.cyan)
                                Text("Action Items")
                                    .font(DS.Typography.subheading())
                                    .foregroundColor(DS.Colors.textPrimary)
                            }

                            ForEach(Array(vm.recommendations.enumerated()), id: \.offset) { idx, rec in
                                HStack(alignment: .top, spacing: DS.Spacing.m) {
                                    ZStack {
                                        Circle()
                                            .fill(DS.Colors.cyan.opacity(0.15))
                                            .frame(width: 28, height: 28)
                                        Text("\(idx + 1)")
                                            .font(DS.Typography.caption())
                                            .foregroundColor(DS.Colors.cyan)
                                    }
                                    Text(rec)
                                        .font(DS.Typography.body())
                                        .foregroundColor(DS.Colors.textSecondary)
                                        .lineSpacing(3)
                                    Spacer()
                                }
                                .padding(.vertical, 4)

                                if idx < vm.recommendations.count - 1 {
                                    Divider().background(DS.Colors.divider)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, DS.Spacing.l)

                    // Priority level
                    DSCard {
                        HStack(spacing: DS.Spacing.m) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Priority Level")
                                    .font(DS.Typography.caption())
                                    .foregroundColor(DS.Colors.textMuted)
                                Text(vm.riskLevel == .high ? "Immediate Action" : vm.riskLevel == .medium ? "Soon" : "When Convenient")
                                    .font(DS.Typography.subheading())
                                    .foregroundColor(vm.riskLevel.color)
                            }
                            Spacer()
                            RiskBadge(level: vm.riskLevel)
                        }
                    }
                    .padding(.horizontal, DS.Spacing.l)

                    // Notes
                    VStack(alignment: .leading, spacing: DS.Spacing.s) {
                        Text("Notes (Optional)")
                            .font(DS.Typography.caption())
                            .foregroundColor(DS.Colors.textMuted)

                        ZStack(alignment: .topLeading) {
                            if vm.notes.isEmpty {
                                Text("Add notes about this crack...")
                                    .font(DS.Typography.body())
                                    .foregroundColor(DS.Colors.textMuted)
                                    .padding(DS.Spacing.m)
                            }
                            TextEditor(text: $vm.notes)
                                .font(DS.Typography.body())
                                .foregroundColor(DS.Colors.textPrimary)
                                .frame(height: 80)
                                .padding(DS.Spacing.s)
                                .scrollContentBackground(.hidden)
                        }
                        .background(DS.Colors.card)
                        .cornerRadius(DS.Radius.m)
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.Radius.m)
                                .stroke(DS.Colors.divider, lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, DS.Spacing.l)

                    // Buttons
                    VStack(spacing: DS.Spacing.m) {
                        PrimaryButton("Save Scan", icon: "checkmark.circle.fill", action: onSave)

                        Button(action: onSave) {
                            Text("Create Repair Task")
                                .font(DS.Typography.subheading(14))
                                .foregroundColor(DS.Colors.cyan)
                        }
                    }
                    .padding(.horizontal, DS.Spacing.l)

                    Spacer(minLength: 60)
                }
            }
        }
    }
}

// MARK: - Image Picker
struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePickerView
        init(_ parent: ImagePickerView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let img = info[.originalImage] as? UIImage {
                parent.image = img
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Scan Detail View
struct ScanDetailView: View {
    let scan: Scan
    @EnvironmentObject var dataStore: DataStore
    @State private var showComparison = false

    var roomName: String {
        guard let rid = scan.roomId, let room = dataStore.rooms.first(where: { $0.id == rid }) else { return "Unknown" }
        return room.name
    }

    var body: some View {
        ZStack {
            DS.Colors.bgPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: DS.Spacing.l) {
                    // Image
                    ZStack {
                        if let img = scan.image {
                            Image(uiImage: img)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 250)
                                .clipped()
                        } else {
                            DS.Colors.bgSecondary
                                .frame(height: 250)
                            VStack {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(DS.Colors.textMuted)
                                Text("No image available")
                                    .font(DS.Typography.caption())
                                    .foregroundColor(DS.Colors.textMuted)
                            }
                        }
                    }
                    .cornerRadius(DS.Radius.l)
                    .padding(.horizontal, DS.Spacing.l)

                    // Info
                    HStack(spacing: DS.Spacing.m) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(scan.crackType.rawValue)
                                .font(DS.Typography.heading())
                                .foregroundColor(DS.Colors.textPrimary)
                            Text(roomName)
                                .font(DS.Typography.caption())
                                .foregroundColor(DS.Colors.textMuted)
                        }
                        Spacer()
                        RiskBadge(level: scan.riskLevel)
                    }
                    .padding(.horizontal, DS.Spacing.l)

                    // Details
                    DSCard {
                        VStack(spacing: DS.Spacing.m) {
                            DetailRow(label: "Type", value: scan.crackType.rawValue)
                            Divider().background(DS.Colors.divider)
                            DetailRow(label: "Risk Level", value: scan.riskLevel.rawValue, color: scan.riskLevel.color)
                            Divider().background(DS.Colors.divider)
                            DetailRow(label: "Width", value: String(format: "%.1f mm", scan.width))
                            Divider().background(DS.Colors.divider)
                            DetailRow(label: "Length", value: String(format: "%.0f mm", scan.length))
                            Divider().background(DS.Colors.divider)
                            DetailRow(label: "Room", value: roomName)
                            Divider().background(DS.Colors.divider)
                            DetailRow(label: "Scanned", value: scan.createdAt.formatted(date: .abbreviated, time: .shortened))
                        }
                    }
                    .padding(.horizontal, DS.Spacing.l)

                    // Recommendations
                    if !scan.recommendations.isEmpty {
                        DSCard {
                            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                                Text("Recommendations")
                                    .font(DS.Typography.subheading())
                                    .foregroundColor(DS.Colors.textPrimary)
                                ForEach(Array(scan.recommendations.enumerated()), id: \.offset) { idx, rec in
                                    HStack(spacing: DS.Spacing.m) {
                                        Circle()
                                            .fill(DS.Colors.cyan.opacity(0.15))
                                            .frame(width: 24, height: 24)
                                            .overlay(
                                                Text("\(idx + 1)")
                                                    .font(DS.Typography.caption(11))
                                                    .foregroundColor(DS.Colors.cyan)
                                            )
                                        Text(rec)
                                            .font(DS.Typography.body())
                                            .foregroundColor(DS.Colors.textSecondary)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, DS.Spacing.l)
                    }

                    if !scan.notes.isEmpty {
                        DSCard {
                            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                                Text("Notes")
                                    .font(DS.Typography.subheading())
                                    .foregroundColor(DS.Colors.textPrimary)
                                Text(scan.notes)
                                    .font(DS.Typography.body())
                                    .foregroundColor(DS.Colors.textSecondary)
                            }
                        }
                        .padding(.horizontal, DS.Spacing.l)
                    }

                    // Action buttons
                    HStack(spacing: DS.Spacing.m) {
                        SecondaryButton("Comparison", icon: "rectangle.split.2x1") {
                            showComparison = true
                        }
                        PrimaryButton("Create Task", icon: "plus.circle") {
                            // Task creation handled in tasks view
                        }
                    }
                    .padding(.horizontal, DS.Spacing.l)

                    Spacer(minLength: 100)
                }
                .padding(.top, DS.Spacing.l)
            }
        }
        .navigationTitle("Scan Detail")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showComparison) {
            ComparisonView(scan: scan)
                .environmentObject(dataStore)
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    var color: Color = DS.Colors.textPrimary

    var body: some View {
        HStack {
            Text(label)
                .font(DS.Typography.body())
                .foregroundColor(DS.Colors.textMuted)
            Spacer()
            Text(value)
                .font(DS.Typography.subheading(14))
                .foregroundColor(color)
        }
    }
}
