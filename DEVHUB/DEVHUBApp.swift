import SwiftUI
import SwiftData

@main
struct DEVHUBApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [ProjectTaskItem.self, StudioProjectRecord.self, DEVHUBNotification.self, ByteWorkItem.self, ProjectMilestoneItem.self])
    }
}
