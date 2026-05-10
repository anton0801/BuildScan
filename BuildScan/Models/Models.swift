import Foundation
import SwiftUI

// MARK: - User
struct User: Codable, Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var email: String
    var createdAt: Date = Date()
}

// MARK: - Crack Type
enum CrackType: String, Codable, CaseIterable {
    case hairline = "Hairline"
    case structural = "Structural"
    case settlement = "Settlement"
    case shrinkage = "Shrinkage"
    case diagonal = "Diagonal"
    case horizontal = "Horizontal"
    case vertical = "Vertical"

    var description: String {
        switch self {
        case .hairline: return "Fine surface crack, typically < 0.2mm wide"
        case .structural: return "Wide crack indicating structural movement"
        case .settlement: return "Caused by uneven foundation settlement"
        case .shrinkage: return "Normal drying/curing crack"
        case .diagonal: return "45° crack at corners of openings"
        case .horizontal: return "Horizontal crack in walls, may indicate pressure"
        case .vertical: return "Vertical crack, often from settling"
        }
    }

    var icon: String {
        switch self {
        case .hairline: return "line.diagonal"
        case .structural: return "exclamationmark.triangle.fill"
        case .settlement: return "arrow.down.to.line"
        case .shrinkage: return "rectangle.compress.vertical"
        case .diagonal: return "arrow.up.right"
        case .horizontal: return "minus"
        case .vertical: return "line.vertical.singlequote.and.slash"
        }
    }
}

// MARK: - Risk Level
enum RiskLevel: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var color: Color {
        switch self {
        case .low: return Color(hex: "#22C55E")
        case .medium: return Color(hex: "#FACC15")
        case .high: return Color(hex: "#EF4444")
        }
    }

    var icon: String {
        switch self {
        case .low: return "checkmark.shield.fill"
        case .medium: return "exclamationmark.shield.fill"
        case .high: return "xmark.shield.fill"
        }
    }

    var description: String {
        switch self {
        case .low: return "Cosmetic damage only. Monitor over time."
        case .medium: return "Attention needed. Plan repair within 3 months."
        case .high: return "Immediate action required. Consult a professional."
        }
    }
}

// MARK: - Scan
struct Scan: Identifiable, Codable {
    var id: String = UUID().uuidString
    var roomId: String?
    var imageData: Data?
    var crackType: CrackType
    var riskLevel: RiskLevel
    var notes: String = ""
    var recommendations: [String] = []
    var createdAt: Date = Date()
    var width: Double = 0.0
    var length: Double = 0.0
    var markPoints: [CGPoint] = []

    var image: UIImage? {
        guard let data = imageData else { return nil }
        return UIImage(data: data)
    }
}

extension Scan {
    static var demo: [Scan] {
        [
            Scan(
                roomId: Room.demo[0].id,
                imageData: nil,
                crackType: .hairline,
                riskLevel: .low,
                notes: "Small hairline crack near window",
                recommendations: ["Apply sealant", "Monitor for 30 days"],
                createdAt: Date().addingTimeInterval(-86400 * 5),
                width: 0.3,
                length: 12.0
            ),
            Scan(
                roomId: Room.demo[1].id,
                imageData: nil,
                crackType: .diagonal,
                riskLevel: .medium,
                notes: "Diagonal crack at door frame corner",
                recommendations: ["Fill with flexible filler", "Check door alignment", "Monitor monthly"],
                createdAt: Date().addingTimeInterval(-86400 * 2),
                width: 1.2,
                length: 25.0
            ),
            Scan(
                roomId: Room.demo[0].id,
                imageData: nil,
                crackType: .structural,
                riskLevel: .high,
                notes: "Wide structural crack with visible movement",
                recommendations: ["Consult structural engineer immediately", "Do not attempt DIY repair", "Document with photos weekly"],
                createdAt: Date().addingTimeInterval(-3600),
                width: 5.0,
                length: 80.0
            )
        ]
    }
}

// MARK: - Room
struct Room: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var icon: String
    var scanCount: Int = 0
    var issueCount: Int = 0

    static var demo: [Room] {
        [
            Room(id: "r1", name: "Living Room", icon: "sofa.fill", scanCount: 3, issueCount: 1),
            Room(id: "r2", name: "Bedroom", icon: "bed.double.fill", scanCount: 2, issueCount: 2),
            Room(id: "r3", name: "Kitchen", icon: "fork.knife", scanCount: 1, issueCount: 0),
            Room(id: "r4", name: "Bathroom", icon: "bathtub.fill", scanCount: 2, issueCount: 1),
            Room(id: "r5", name: "Basement", icon: "arrow.down.to.line", scanCount: 4, issueCount: 3)
        ]
    }
}

// MARK: - Report
struct Report: Identifiable, Codable {
    var id: String = UUID().uuidString
    var title: String
    var scanIds: [String] = []
    var createdAt: Date = Date()
    var notes: String = ""
    var summary: String = ""
}

// MARK: - Task
struct RepairTask: Identifiable, Codable {
    var id: String = UUID().uuidString
    var title: String
    var description: String
    var scanId: String?
    var roomId: String?
    var priority: TaskPriority
    var status: TaskStatus
    var dueDate: Date?
    var createdAt: Date = Date()
}

enum TaskPriority: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var color: Color {
        switch self {
        case .low: return Color(hex: "#22C55E")
        case .medium: return Color(hex: "#FACC15")
        case .high: return Color(hex: "#EF4444")
        }
    }
}

enum TaskStatus: String, Codable, CaseIterable {
    case pending = "Pending"
    case inProgress = "In Progress"
    case done = "Done"
}

// MARK: - Activity
struct Activity: Identifiable, Codable {
    var id: String = UUID().uuidString
    var type: ActivityType
    var description: String
    var timestamp: Date = Date()
    var relatedId: String?
}

enum ActivityType: String, Codable {
    case scan = "scan"
    case analysis = "analysis"
    case task = "task"
    case report = "report"

    var icon: String {
        switch self {
        case .scan: return "camera.fill"
        case .analysis: return "waveform.path.ecg"
        case .task: return "checkmark.circle.fill"
        case .report: return "doc.text.fill"
        }
    }

    var color: Color {
        switch self {
        case .scan: return Color(hex: "#22D3EE")
        case .analysis: return Color(hex: "#6366F1")
        case .task: return Color(hex: "#22C55E")
        case .report: return Color(hex: "#818CF8")
        }
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
