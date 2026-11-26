import Foundation
import SwiftData

@Model
final class StudioProjectRecord {
    @Attribute(.unique) var id: String
    var name: String
    var subtitle: String
    var platform: String
    var category: String
    var repository: String
    var progress: Double
    var statusRawValue: String
    var symbol: String
    var accent: String
    var nextMilestone: String
    var isArchived: Bool
    var createdAt: Date

    var status: ProjectStatus {
        ProjectStatus(rawValue: statusRawValue) ?? .planning
    }

    var project: StudioProject {
        StudioProject(id: id, name: name, subtitle: subtitle, platform: platform,
                      category: category, repository: repository, progress: progress,
                      status: status, symbol: symbol, accent: accent, nextMilestone: nextMilestone)
    }

    init(project: StudioProject, isArchived: Bool = false) {
        id = project.id
        name = project.name
        subtitle = project.subtitle
        platform = project.platform
        category = project.category
        repository = project.repository
        progress = project.progress
        statusRawValue = project.status.rawValue
        symbol = project.symbol
        accent = project.accent
        nextMilestone = project.nextMilestone
        self.isArchived = isArchived
        createdAt = .now
    }
}
