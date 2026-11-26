import Foundation
import SwiftData

@Model
final class ProjectTaskItem {
    @Attribute(.unique) var id: String
    var projectID: String
    var title: String
    var isCompleted: Bool
    var weight: Int?
    var milestoneID: String?
    var createdAt: Date

    init(projectID: String, title: String, isCompleted: Bool = false, weight: Int = 1, milestoneID: String? = nil) {
        self.id = UUID().uuidString
        self.projectID = projectID
        self.title = title
        self.isCompleted = isCompleted
        self.weight = max(1, min(weight, 5))
        self.milestoneID = milestoneID
        self.createdAt = .now
    }
}
