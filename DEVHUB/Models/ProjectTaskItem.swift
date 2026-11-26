import Foundation
import SwiftData

@Model
final class ProjectTaskItem {
    @Attribute(.unique) var id: String
    var projectID: String
    var title: String
    var isCompleted: Bool
    var createdAt: Date

    init(projectID: String, title: String, isCompleted: Bool = false) {
        self.id = UUID().uuidString
        self.projectID = projectID
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = .now
    }
}
