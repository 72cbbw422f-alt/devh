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

    init(title: String, message: String, category: String = "system", createdAt: Date = .now, isRead: Bool = false) {
        self.id = UUID()
        self.title = title
        self.message = message
        self.category = category
        self.createdAt = createdAt
        self.isRead = isRead
    }
}
