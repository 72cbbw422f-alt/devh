import SwiftUI
import UserNotifications

struct NotificationPermissionCard: View {
    @State private var status: UNAuthorizationStatus = .notDetermined
    @State private var message: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                Image(systemName: status == .authorized ? "bell.badge.fill" : "bell")
                    .foregroundStyle(StudioTheme.accent)
                Text("Aviseringar på iPhone")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(StudioTheme.text)
                Spacer()
                Text(status == .authorized ? "Aktiverat" : "Inte aktiverat")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(status == .authorized ? Color(hex: "6BCB9A") : StudioTheme.muted)
            }
            Text("Tillåt lokala aviseringar när DEVHUB upptäcker nya händelser. Pushbevakning när appen är helt stängd kräver en separat serverkoppling.")
                .font(.caption)
                .foregroundStyle(StudioTheme.muted)
            if status != .authorized {
                Button {
                    Task { await requestPermission() }
                } label: {
                    Label("Aktivera aviseringar", systemImage: "bell.badge")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                }
                .buttonStyle(.borderedProminent)
                .tint(StudioTheme.accent)
            }
            if let message {
                Text(message).font(.caption2).foregroundStyle(StudioTheme.muted)
            }
        }
        .padding(13)
        .background(StudioTheme.surface, in: RoundedRectangle(cornerRadius: 13))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(StudioTheme.border, lineWidth: 1))
        .task { await refreshStatus() }
    }

    @MainActor
    private func refreshStatus() async {
        status = await DEVHUBLocalNotifications.shared.authorizationStatus()
    }

    @MainActor
    private func requestPermission() async {
        do {
            let granted = try await DEVHUBLocalNotifications.shared.requestPermission()
            status = granted ? .authorized : .denied
            message = granted ? "Aviseringar är aktiverade." : "Tillstånd nekades. Ändra det i Inställningar > Notiser > DEVHUB."
        } catch {
            message = "Kunde inte begära notistillstånd: \(error.localizedDescription)"
        }
    }
}
