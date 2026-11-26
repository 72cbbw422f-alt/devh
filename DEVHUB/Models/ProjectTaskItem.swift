import Foundation
import SwiftData

@Model
final class ProjectTaskItem {
    @Attribute(.unique) var id: String
    var projectID: String
    var title: String
    var isCompleted: Bool
    var statusRawValue: String?
    var weight: Int?
    var milestoneID: String?
    var createdAt: Date

    var statusLabel: String {
        switch statusRawValue {
        case "inProgress": "Pågår"
        case "verified": "Verifierat klar"
        case "completed": "Klar"
        default: "Föreslagen"
        }
    }

    var statusSymbol: String {
        switch statusRawValue {
        case "inProgress": "arrow.triangle.2.circlepath"
        case "verified": "checkmark.seal.fill"
        case "completed": "checkmark.circle.fill"
        default: "circle"
        }
    }

    init(projectID: String, title: String, isCompleted: Bool = false, weight: Int = 1, milestoneID: String? = nil) {
        self.id = UUID().uuidString
        self.projectID = projectID
        self.title = title
        self.isCompleted = isCompleted
        self.statusRawValue = isCompleted ? "completed" : "proposed"
        self.weight = max(1, min(weight, 5))
        self.milestoneID = milestoneID
        self.createdAt = .now
    }
}
