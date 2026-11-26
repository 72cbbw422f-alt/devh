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
    var verificationPRURL: String?
    var verificationCommitSHA: String?
    var verificationWorkflowURL: String?
    var createdAt: Date

    var statusLabel: String {
        if statusRawValue == nil && isCompleted { return "Klar" }
        switch statusRawValue {
        case "inProgress": return "Pågår"
        case "verified": return "Verifierat klar"
        case "completed": return "Klar"
        default: return "Föreslagen"
        }
    }

    var statusSymbol: String {
        if statusRawValue == nil && isCompleted { return "checkmark.circle.fill" }
        switch statusRawValue {
        case "inProgress": return "arrow.triangle.2.circlepath"
        case "verified": return "checkmark.seal.fill"
        case "completed": return "checkmark.circle.fill"
        default: return "circle"
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
