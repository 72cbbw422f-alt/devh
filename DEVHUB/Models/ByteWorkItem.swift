import Foundation
import SwiftData

@Model
final class ByteWorkItem {
    @Attribute(.unique) var id: String
    var projectRepository: String
    var dispatchRequestID: String = ""
    var title: String
    var statusRawValue: String
    var createdAt: Date
    var updatedAt: Date
    var workflowURL: String?
    var workflowRunID: Int?
    var analysisText: String?
    var taskProposalJSON: String?
    var workModeRawValue: String = "approval"
    var conversationResponseID: String?
    var inputTokens: Int = 0
    var cachedInputTokens: Int = 0
    var outputTokens: Int = 0
    var costUSD: Double = 0
    var patchPreview: String?
    var baseCommitSHA: String?
    var patchStatusRawValue: String = "pending"
    var patchWorkflowRunID: Int?
    var patchWorkflowURL: String?
    var patchPullRequestURL: String?
    var patchDispatchedAt: Date?
    var patchDispatchRequestID: String?
    var patchFailureDetails: String?
    var workflowFailureDetails: String?
    var analysisRecoveryDetails: String?

    var workModeLabel: String {
        switch workModeRawValue {
        case "quick": "Snabbt svar"
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
        dispatchRequestID = UUID().uuidString
        self.title = title
        statusRawValue = "queued"
        createdAt = .now
        updatedAt = .now
        workflowURL = nil
        workflowRunID = nil
        analysisText = nil
        taskProposalJSON = nil
        workModeRawValue = workMode
        conversationResponseID = nil
        baseCommitSHA = nil
        patchStatusRawValue = "pending"
        patchWorkflowRunID = nil
        patchWorkflowURL = nil
        patchPullRequestURL = nil
        patchDispatchedAt = nil
        patchFailureDetails = nil
        workflowFailureDetails = nil
        analysisRecoveryDetails = nil
    }
}
