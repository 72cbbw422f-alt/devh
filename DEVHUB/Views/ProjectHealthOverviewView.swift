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

            if let lastRefresh {
                Text("Senast kontrollerad \(lastRefresh.formatted(date: .omitted, time: .shortened)) · uppdateras manuellt")
                    .font(.system(size: 9)).foregroundStyle(StudioTheme.muted)
            }
        }
        .task { await refresh() }
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
                Text("öppna ärenden")
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
                async let workItemsResult = service.fetchOpenWorkItems(repository: project.repository)
                let snapshot = try await snapshotResult
                let workflow = try await workflowResult
                let workItems = try await workItemsResult
                results.append(ProjectHealthState(
                    id: project.id,
                    projectName: project.name,
                    repository: snapshot.0.fullName,
                    workflowStatus: workflow?.status ?? "none",
                    workflowConclusion: workflow?.status == "completed" ? workflow?.conclusion : nil,
                    openItemsCount: workItems.count,
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
