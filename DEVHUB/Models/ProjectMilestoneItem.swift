import Foundation
import SwiftData

@Model
final class ProjectMilestoneItem {
    @Attribute(.unique) var id: String
    var projectID: String
    var title: String
    var isCompleted: Bool
    var sortOrder: Int
    var updatedAt: Date

    init(projectID: String, title: String, sortOrder: Int, isCompleted: Bool = false) {
        id = UUID().uuidString
        self.projectID = projectID
        self.title = title
        self.sortOrder = sortOrder
        self.isCompleted = isCompleted
        updatedAt = .now
    }
}
