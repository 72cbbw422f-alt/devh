import Foundation
import SwiftData

@Model
final class ByteWorkItem {
    @Attribute(.unique) var id: String
    var projectRepository: String
    var title: String
    var statusRawValue: String
    var createdAt: Date
    var updatedAt: Date
    var workflowURL: String?
    var workflowRunID: Int?
    var analysisText: String?
    var workModeRawValue: String = "approval"
    var conversationResponseID: String?

    var workModeLabel: String {
        switch workModeRawValue {
        case "collaborate": "Samarbeta"
        case "autopilot": "Autopilot"
        default: "Godkänn först"
        }
    }

    var statusLabel: String {
        switch statusRawValue {
        case "running": "Pågår"
        case "completed": "Klar"
        case "failed": "Misslyckades"
        default: "I kö"
        }
    }

    init(projectRepository: String, title: String, workMode: String = "approval") {
        id = UUID().uuidString
        self.projectRepository = projectRepository
        self.title = title
        statusRawValue = "queued"
        createdAt = .now
        updatedAt = .now
        workflowURL = nil
        workflowRunID = nil
        analysisText = nil
        workModeRawValue = workMode
        conversationResponseID = nil
    }
}
