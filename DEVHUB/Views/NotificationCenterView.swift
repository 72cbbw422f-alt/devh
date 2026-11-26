import SwiftUI
import SwiftData

struct NotificationCenterView: View {
    @Query(sort: \DEVHUBNotification.createdAt, order: .reverse) private var notifications: [DEVHUBNotification]

    private var unreadCount: Int { notifications.filter { !$0.isRead }.count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notiser").font(.largeTitle.bold()).foregroundStyle(StudioTheme.text)
                        Text(unreadCount == 0 ? "Du är helt uppdaterad." : "\(unreadCount) olästa notiser")
                            .font(.subheadline).foregroundStyle(StudioTheme.muted)
                    }
                    Spacer()
                    if unreadCount > 0 {
                        Button("Markera alla lästa") {
                            notifications.filter { !$0.isRead }.forEach { $0.isRead = true }
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(StudioTheme.accent)
                    }
                }

                if notifications.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bell.badge").font(.system(size: 34)).foregroundStyle(StudioTheme.accent)
                        Text("Inga notiser ännu").font(.headline).foregroundStyle(StudioTheme.text)
                        Text("Byggresultat, nya ärenden och Byte-rapporter visas här när de upptäcks.")
                            .font(.subheadline).multilineTextAlignment(.center).foregroundStyle(StudioTheme.muted)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 44)
                    .background(StudioTheme.surface, in: RoundedRectangle(cornerRadius: 16))
                } else {
                    ForEach(notifications) { item in
                        notificationRow(item)
                    }
                }
            }.padding()
        }
        .background(StudioTheme.background.ignoresSafeArea())
        .navigationTitle("Notiser")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func notificationRow(_ item: DEVHUBNotification) -> some View {
        let content = HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon(for: item.category))
                .foregroundStyle(StudioTheme.accent)
                .frame(width: 36, height: 36)
                .background(StudioTheme.elevated, in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title).font(.subheadline.weight(.semibold)).foregroundStyle(StudioTheme.text)
                Text(item.message).font(.caption).foregroundStyle(StudioTheme.secondaryText)
                Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2).foregroundStyle(StudioTheme.muted)
            }
            Spacer()
            if !item.isRead {
                Circle().fill(StudioTheme.accent).frame(width: 7, height: 7)
            }
            if item.destinationURL != nil {
                Image(systemName: "arrow.up.right").font(.caption2).foregroundStyle(StudioTheme.muted)
            }
        }
        .padding(13)
        .background(StudioTheme.surface, in: RoundedRectangle(cornerRadius: 13))
        .contentShape(Rectangle())

        if let rawURL = item.destinationURL, let url = URL(string: rawURL) {
            Link(destination: url) {
                content
            }
            .simultaneousGesture(TapGesture().onEnded { item.isRead = true })
        } else {
            content.onTapGesture { item.isRead = true }
        }
    }

    private func icon(for category: String) -> String {
        switch category {
        case "build": "hammer.fill"
        case "approval": "checkmark.seal.fill"
        case "issue": "exclamationmark.triangle.fill"
        case "assistant": "sparkles"
        case "budget": "creditcard.fill"
        default: "bell.fill"
        }
    }
}
