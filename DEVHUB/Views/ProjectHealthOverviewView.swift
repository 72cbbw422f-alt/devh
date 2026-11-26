import SwiftUI

private struct ProjectHealthState: Identifiable {
    let id: String
    let projectName: String
    let repository: String
    let workflowStatus: String
    let workflowConclusion: String?
    let openItemsCount: Int
    let checkedAt: Date
    let error: String?

    var statusTitle: String {
        if error != nil { return "Kan inte nå GitHub" }
        guard let workflowConclusion else {
            return workflowStatus == "none" ? "Ingen byggning hittad" : "Actions \(workflowStatus)"
        }
        switch workflowConclusion {
        case "success": return "Senaste byggning lyckades"
        case "failure": return "Senaste byggning misslyckades"
        case "cancelled": return "Byggning avbruten"
        case "skipped": return "Byggning hoppades över"
        default: return "Byggning: \(workflowConclusion)"
        }
    }

    var statusColor: Color {
        if error != nil { return Color(hex: "E5B86B") }
        if workflowConclusion == "success" { return Color(hex: "6BCB9A") }
        if workflowConclusion == "failure" { return Color(hex: "E56B78") }
        if workflowStatus == "in_progress" || workflowStatus == "queued" { return Color(hex: "E5B86B") }
        return StudioTheme.muted
    }
}

struct ProjectHealthOverviewView: View {
    let projects: [StudioProject]
    @State private var states: [ProjectHealthState] = []
    @State private var isLoading = false
    @State private var lastRefresh: Date?

    private var attentionStates: [ProjectHealthState] {
        states.filter {
            $0.error != nil || $0.workflowConclusion == "failure" ||
            $0.workflowStatus == "in_progress" || $0.workflowStatus == "queued" ||
            $0.openItemsCount > 0
        }.sorted { lhs, rhs in
            func rank(_ state: ProjectHealthState) -> Int {
                if state.workflowConclusion == "failure" { return 0 }
                if state.error != nil { return 1 }
                if state.workflowStatus == "in_progress" || state.workflowStatus == "queued" { return 2 }
                return 3
            }
            return rank(lhs) < rank(rhs)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                SectionHeading(eyebrow: "LIVE FRÅN GITHUB", title: "Projektens hälsa")
                Spacer()
                if isLoading {
                    ProgressView().tint(StudioTheme.accent)
                } else {
                    Button { Task { await refresh() } } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(StudioTheme.accent)
                    }
                    .accessibilityLabel("Uppdatera projektstatus")
                }
            }

            if states.isEmpty && isLoading {
                HStack(spacing: 9) {
                    ProgressView().tint(StudioTheme.accent)
                    Text("Kontrollerar projektens GitHub-status…")
                        .font(.caption).foregroundStyle(StudioTheme.muted)
                }
                .padding(15)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(StudioTheme.surface, in: RoundedRectangle(cornerRadius: 14))
            } else if states.isEmpty {
                Text("Ingen projektstatus har hämtats ännu.")
                    .font(.caption).foregroundStyle(StudioTheme.muted)
            } else {
                VStack(spacing: 0) {
                    ForEach(states) { state in
                        healthRow(state)
                        if state.id != states.last?.id {
                            Divider().overlay(StudioTheme.border)
                        }
                    }
                }
                .padding(.horizontal, 13)
                .background(StudioTheme.surface, in: RoundedRectangle(cornerRadius: 15))
                .overlay(RoundedRectangle(cornerRadius: 15).stroke(StudioTheme.border, lineWidth: 1))
            }

            attentionCard

            if let lastRefresh {
                Text("Senast kontrollerad \(lastRefresh.formatted(date: .omitted, time: .shortened)) · uppdateras manuellt")
                    .font(.system(size: 9)).foregroundStyle(StudioTheme.muted)
            }
        }
        .task { await refresh() }
    }

    private var attentionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeading(eyebrow: "PRIORITERING", title: "Fokus just nu")
            if states.isEmpty {
                Text("Fokusförslag visas när projektstatusen har hämtats.")
                    .font(.caption).foregroundStyle(StudioTheme.muted)
            } else if attentionStates.isEmpty {
                Label("Inget akut – projekten ser stabila ut", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(hex: "6BCB9A"))
            } else {
                ForEach(Array(attentionStates.prefix(3))) { state in
                    HStack(alignment: .top, spacing: 9) {
                        Image(systemName: state.workflowConclusion == "failure" ? "xmark.octagon.fill" : (state.error != nil ? "wifi.exclamationmark" : "arrow.up.right.circle.fill"))
                            .foregroundStyle(state.statusColor)
                            .frame(width: 17)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(state.projectName)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(StudioTheme.text)
                            Text(focusReason(for: state))
                                .font(.system(size: 10))
                                .foregroundStyle(StudioTheme.muted)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(StudioTheme.surface, in: RoundedRectangle(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(StudioTheme.border, lineWidth: 1))
    }

    private func focusReason(for state: ProjectHealthState) -> String {
        if state.workflowConclusion == "failure" { return "Åtgärda felet i senaste bygget." }
        if state.error != nil { return "Kontrollera GitHub-anslutningen." }
        if state.workflowStatus == "in_progress" || state.workflowStatus == "queued" { return "Byggning pågår eller väntar." }
        return "\(state.openItemsCount) öppna ärenden att gå igenom."
    }

    private func healthRow(_ state: ProjectHealthState) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Circle()
                .fill(state.statusColor)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 3) {
                Text(state.projectName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(StudioTheme.text)
                Text(state.statusTitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(state.statusColor)
                if let error = state.error {
                    Text(error)
                        .font(.system(size: 9))
                        .foregroundStyle(StudioTheme.muted)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 3) {
                Text("\(state.openItemsCount)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(StudioTheme.text)
                Text("öppna ärenden totalt")
                    .font(.system(size: 8))
                    .foregroundStyle(StudioTheme.muted)
            }
        }
        .padding(.vertical, 11)
    }

    @MainActor
    private func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        defer {
            isLoading = false
            lastRefresh = .now
        }

        let service = GitHubRepositoryService()
        var results: [ProjectHealthState] = []
        for project in projects where !project.repository.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            do {
                async let snapshotResult = service.fetchSnapshot(repository: project.repository)
                async let workflowResult = service.fetchLatestWorkflowRun(repository: project.repository)
                let snapshot = try await snapshotResult
                let workflow = try await workflowResult
                results.append(ProjectHealthState(
                    id: project.id,
                    projectName: project.name,
                    repository: snapshot.0.fullName,
                    workflowStatus: workflow?.status ?? "none",
                    workflowConclusion: workflow?.status == "completed" ? workflow?.conclusion : nil,
                    openItemsCount: snapshot.0.openIssuesCount,
                    checkedAt: .now,
                    error: nil
                ))
            } catch {
                results.append(ProjectHealthState(
                    id: project.id,
                    projectName: project.name,
                    repository: project.repository,
                    workflowStatus: "unknown",
                    workflowConclusion: nil,
                    openItemsCount: 0,
                    checkedAt: .now,
                    error: error.localizedDescription
                ))
            }
        }
        states = results
    }
}
