import Foundation
import SwiftData

@Model
final class DEVHUBNotification {
    var id: UUID
    var title: String
    var message: String
    var category: String
    var createdAt: Date
    var isRead: Bool
    var sourceKey: String?
    var destinationURL: String?

    init(title: String, message: String, category: String = "system", createdAt: Date = .now, isRead: Bool = false, sourceKey: String? = nil, destinationURL: String? = nil) {
        self.id = UUID()
        self.title = title
        self.message = message
        self.category = category
        self.createdAt = createdAt
        self.isRead = isRead
        self.sourceKey = sourceKey
        self.destinationURL = destinationURL
    }
}
