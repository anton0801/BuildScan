import SwiftUI
import Combine
import UserNotifications

// MARK: - AppState (Global)
class AppState: ObservableObject {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("userName") var userName: String = ""
    @AppStorage("userEmail") var userEmail: String = ""
    @AppStorage("appTheme") var appTheme: String = "dark"
    @AppStorage("measurementUnit") var measurementUnit: String = "mm"
    @AppStorage("aiAnalysisEnabled") var aiAnalysisEnabled: Bool = true
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = false
    @AppStorage("weeklyReportEnabled") var weeklyReportEnabled: Bool = false
    @AppStorage("reminderDays") var reminderDays: Int = 30

    @Published var selectedTab: Int = 0
    @Published var showScanSheet: Bool = false

    var colorScheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    func logout() {
        isLoggedIn = false
        userName = ""
        userEmail = ""
    }

    func deleteAccount() {
        logout()
        // Clear all local data
        UserDefaults.standard.removeObject(forKey: "scansData")
        UserDefaults.standard.removeObject(forKey: "roomsData")
        UserDefaults.standard.removeObject(forKey: "tasksData")
        UserDefaults.standard.removeObject(forKey: "reportsData")
        UserDefaults.standard.removeObject(forKey: "activitiesData")
    }
}

// MARK: - Auth ViewModel
class AuthViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var isRegisterMode: Bool = false

    var appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    func loginWithDemo() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.appState.userName = "Demo User"
            self.appState.userEmail = "demo@buildscan.app"
            self.appState.isLoggedIn = true
            self.isLoading = false
        }
    }

    func login() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.appState.userName = "User"
            self.appState.userEmail = self.email
            self.appState.isLoggedIn = true
            self.isLoading = false
        }
    }

    func register() {
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.appState.userName = self.name
            self.appState.userEmail = self.email
            self.appState.isLoggedIn = true
            self.isLoading = false
        }
    }
}

// MARK: - Data Store ViewModel
class DataStore: ObservableObject {
    @Published var scans: [Scan] = []
    @Published var rooms: [Room] = []
    @Published var tasks: [RepairTask] = []
    @Published var reports: [Report] = []
    @Published var activities: [Activity] = []

    init() {
        loadAll()
    }

    private func loadAll() {
        loadScans()
        loadRooms()
        loadTasks()
        loadReports()
        loadActivities()

        if rooms.isEmpty {
            rooms = Room.demo
            saveRooms()
        }
        if scans.isEmpty {
            scans = Scan.demo
            saveScans()
        }
    }

    // MARK: Scans
    func addScan(_ scan: Scan) {
        scans.insert(scan, at: 0)
        saveScans()
        let activity = Activity(type: .scan, description: "New scan: \(scan.crackType.rawValue) crack", relatedId: scan.id)
        addActivity(activity)
        updateRoomScanCount(roomId: scan.roomId)
    }

    func deleteScan(_ scan: Scan) {
        scans.removeAll { $0.id == scan.id }
        saveScans()
    }

    func updateScan(_ scan: Scan) {
        if let idx = scans.firstIndex(where: { $0.id == scan.id }) {
            scans[idx] = scan
            saveScans()
        }
    }

    private func updateRoomScanCount(roomId: String?) {
        guard let rid = roomId, let idx = rooms.firstIndex(where: { $0.id == rid }) else { return }
        rooms[idx].scanCount += 1
        saveRooms()
    }

    func scansForRoom(_ roomId: String) -> [Scan] {
        scans.filter { $0.roomId == roomId }
    }

    var recentScans: [Scan] { Array(scans.prefix(5)) }

    var issueCount: Int { scans.filter { $0.riskLevel != .low }.count }

    var highRiskCount: Int { scans.filter { $0.riskLevel == .high }.count }

    // MARK: Rooms
    func addRoom(_ room: Room) {
        rooms.append(room)
        saveRooms()
    }

    func deleteRoom(_ room: Room) {
        rooms.removeAll { $0.id == room.id }
        saveRooms()
    }

    func updateRoom(_ room: Room) {
        if let idx = rooms.firstIndex(where: { $0.id == room.id }) {
            rooms[idx] = room
            saveRooms()
        }
    }

    // MARK: Tasks
    func addTask(_ task: RepairTask) {
        tasks.insert(task, at: 0)
        saveTasks()
        let activity = Activity(type: .task, description: "New task: \(task.title)", relatedId: task.id)
        addActivity(activity)
    }

    func deleteTask(_ task: RepairTask) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }

    func updateTask(_ task: RepairTask) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx] = task
            saveTasks()
        }
    }

    // MARK: Reports
    func addReport(_ report: Report) {
        reports.insert(report, at: 0)
        saveReports()
        let activity = Activity(type: .report, description: "Report generated: \(report.title)", relatedId: report.id)
        addActivity(activity)
    }

    func deleteReport(_ report: Report) {
        reports.removeAll { $0.id == report.id }
        saveReports()
    }

    // MARK: Activities
    func addActivity(_ activity: Activity) {
        activities.insert(activity, at: 0)
        if activities.count > 50 { activities = Array(activities.prefix(50)) }
        saveActivities()
    }

    // MARK: Persistence
    private func saveScans() {
        if let data = try? JSONEncoder().encode(scans) {
            UserDefaults.standard.set(data, forKey: "scansData")
        }
    }

    private func loadScans() {
        if let data = UserDefaults.standard.data(forKey: "scansData"),
           let decoded = try? JSONDecoder().decode([Scan].self, from: data) {
            scans = decoded
        }
    }

    private func saveRooms() {
        if let data = try? JSONEncoder().encode(rooms) {
            UserDefaults.standard.set(data, forKey: "roomsData")
        }
    }

    private func loadRooms() {
        if let data = UserDefaults.standard.data(forKey: "roomsData"),
           let decoded = try? JSONDecoder().decode([Room].self, from: data) {
            rooms = decoded
        }
    }

    private func saveTasks() {
        if let data = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(data, forKey: "tasksData")
        }
    }

    private func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: "tasksData"),
           let decoded = try? JSONDecoder().decode([RepairTask].self, from: data) {
            tasks = decoded
        }
    }

    private func saveReports() {
        if let data = try? JSONEncoder().encode(reports) {
            UserDefaults.standard.set(data, forKey: "reportsData")
        }
    }

    private func loadReports() {
        if let data = UserDefaults.standard.data(forKey: "reportsData"),
           let decoded = try? JSONDecoder().decode([Report].self, from: data) {
            reports = decoded
        }
    }

    private func saveActivities() {
        if let data = try? JSONEncoder().encode(activities) {
            UserDefaults.standard.set(data, forKey: "activitiesData")
        }
    }

    private func loadActivities() {
        if let data = UserDefaults.standard.data(forKey: "activitiesData"),
           let decoded = try? JSONDecoder().decode([Activity].self, from: data) {
            activities = decoded
        }
    }
}

// MARK: - Scan ViewModel
class ScanViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var markPoints: [CGPoint] = []
    @Published var crackType: CrackType = .hairline
    @Published var riskLevel: RiskLevel = .low
    @Published var notes: String = ""
    @Published var selectedRoomId: String?
    @Published var isAnalyzing: Bool = false
    @Published var analysisComplete: Bool = false
    @Published var width: Double = 0.5
    @Published var length: Double = 10.0
    @Published var recommendations: [String] = []
    @Published var step: ScanStep = .camera

    enum ScanStep {
        case camera, mark, analysis, riskLevel, recommendations, save
    }

    func runAnalysis() {
        isAnalyzing = true
        // Simulate AI analysis
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.performAnalysis()
            self.isAnalyzing = false
            self.analysisComplete = true
        }
    }

    private func performAnalysis() {
        // Determine crack type from mark points
        if markPoints.count >= 2 {
            let dx = abs(markPoints.last!.x - markPoints.first!.x)
            let dy = abs(markPoints.last!.y - markPoints.first!.y)
            if dy < dx * 0.3 { crackType = .horizontal }
            else if dx < dy * 0.3 { crackType = .vertical }
            else { crackType = .diagonal }
        }

        // Simulate width/risk calculation
        let pointCount = Double(markPoints.count)
        width = max(0.2, min(6.0, pointCount * 0.3))
        length = max(5.0, pointCount * 4.5)

        // Determine risk
        if width < 0.5 { riskLevel = .low }
        else if width < 2.0 { riskLevel = .medium }
        else { riskLevel = .high }

        recommendations = generateRecommendations()
    }

    private func generateRecommendations() -> [String] {
        switch riskLevel {
        case .low:
            return ["Fill with flexible sealant", "Paint over after drying", "Monitor monthly"]
        case .medium:
            return ["Use high-grade crack filler", "Check for moisture ingress", "Monitor weekly for 2 months", "Consider professional inspection"]
        case .high:
            return ["Do not attempt DIY repair", "Contact structural engineer immediately", "Document crack dimensions weekly", "Evacuate if cracks widen rapidly"]
        }
    }

    func buildScan() -> Scan {
        var scan = Scan(
            roomId: selectedRoomId,
            imageData: capturedImage?.jpegData(compressionQuality: 0.7),
            crackType: crackType,
            riskLevel: riskLevel,
            notes: notes,
            recommendations: recommendations,
            width: width,
            length: length,
            markPoints: markPoints
        )
        return scan
    }

    func reset() {
        capturedImage = nil
        markPoints = []
        crackType = .hairline
        riskLevel = .low
        notes = ""
        selectedRoomId = nil
        isAnalyzing = false
        analysisComplete = false
        width = 0.5
        length = 10.0
        recommendations = []
        step = .camera
    }
}

// MARK: - Settings ViewModel
class SettingsViewModel: ObservableObject {
    var appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    func requestNotificationPermission(enabled: Bool) {
        if enabled {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                DispatchQueue.main.async {
                    self.appState.notificationsEnabled = granted
                    if granted { self.scheduleReminder() }
                }
            }
        } else {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            appState.notificationsEnabled = false
        }
    }

    func scheduleReminder() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        let content = UNMutableNotificationContent()
        content.title = "Time to check your walls"
        content.body = "It's been a while. Scan your walls for new cracks or changes."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 10
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "wall_reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleWeeklyReport(enabled: Bool) {
        if enabled {
            let content = UNMutableNotificationContent()
            content.title = "Weekly Wall Report Ready"
            content.body = "Your weekly wall health summary is ready to view."
            content.sound = .default

            var dateComponents = DateComponents()
            dateComponents.weekday = 2 // Monday
            dateComponents.hour = 9
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: "weekly_report", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        } else {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["weekly_report"])
        }
    }
}
