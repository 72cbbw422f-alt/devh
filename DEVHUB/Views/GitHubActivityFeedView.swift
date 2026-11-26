import SwiftUI

private struct GitHubActivityItem: Identifiable {
    let id: String
    let projectName: String
    let repositoryURL: URL
    let commitURL: URL?
    let message: String?
    let pushedAt: Date?
    let workflowLabel: String?
    let workflowURL: URL?
    let workflowSucceeded: Bool?
    let openWorkItems: [GitHubOpenWorkItem]
}

struct GitHubActivityFeedView: View {
    let projects: [StudioProject]
    @State private var items: [GitHubActivityItem] = []
    @State private var isLoading = false
    @State private var hasLoaded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            activityContent
        }
        .background(StudioTheme.surface, in: RoundedRectangle(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(StudioTheme.border, lineWidth: 1))
        .overlay(alignment: .topTrailing) { refreshButton }
        .task { await refresh() }
    }

    @ViewBuilder
    private var activityContent: some View {
        if isLoading && items.isEmpty {
            loadingState
        } else if items.isEmpty {
            emptyState
        } else {
            VStack(spacing: 0) {
                ForEach(items) { item in
                    activityRow(item)
                    if item.id != items.last?.id {
                        Divider().overlay(StudioTheme.border)
                    }
                }
            }
            .padding(.horizontal, 15)
        }
    }

    private var loadingState: some View {
        HStack(spacing: 10) {
            ProgressView().tint(StudioTheme.accent)
            Text("Hämtar senaste aktivitet från GitHub…")
                .font(.caption).foregroundStyle(StudioTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.triangle.branch")
                .font(.title2).foregroundStyle(StudioTheme.accent)
            Text(hasLoaded ? "Ingen GitHub-aktivitet hittades" : "Aktivitetsflödet väntar")
                .font(.subheadline.weight(.semibold)).foregroundStyle(StudioTheme.text)
            Text("Kontrollera att projekten har publika GitHub-repositoryn kopplade.")
                .font(.caption).foregroundStyle(StudioTheme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
    }

    private func activityRow(_ item: GitHubActivityItem) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: "arrow.triangle.branch")
                .font(.caption.weight(.bold))
                .foregroundStyle(StudioTheme.accentCyan)
                .frame(width: 30, height: 30)
                .background(StudioTheme.elevated, in: RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 5) {
                projectHeader(item)
                Text(item.message ?? "Repository uppdaterat")
                    .font(.caption).foregroundStyle(StudioTheme.secondaryText)
                    .lineLimit(2)
                repositoryLinks(item)
                openWorkSection(item.openWorkItems)
            }
        }
        .padding(.vertical, 12)
    }

    private func projectHeader(_ item: GitHubActivityItem) -> some View {
        HStack {
            Text(item.projectName)
                .font(.caption.weight(.bold)).foregroundStyle(StudioTheme.text)
            Spacer()
            if let pushedAt = item.pushedAt {
                Text(pushedAt, style: .relative)
                    .font(.system(size: 9)).foregroundStyle(StudioTheme.muted)
            }
        }
    }

    private func repositoryLinks(_ item: GitHubActivityItem) -> some View {
        HStack(spacing: 12) {
            Link("Repository", destination: item.repositoryURL)
            if let commitURL = item.commitURL {
                Link("Commit", destination: commitURL)
            }
            if let workflowURL = item.workflowURL, let workflowLabel = item.workflowLabel {
                Link(destination: workflowURL) {
                    Label(workflowLabel, systemImage: workflowSymbol(item))
                        .foregroundStyle(workflowColor(item))
                }
            }
        }
        .font(.system(size: 10, weight: .semibold))
        .tint(StudioTheme.accent)
    }

    private func workflowSymbol(_ item: GitHubActivityItem) -> String {
        item.workflowSucceeded == true ? "checkmark.circle.fill" : "exclamationmark.circle.fill"
    }

    private func workflowColor(_ item: GitHubActivityItem) -> Color {
        item.workflowSucceeded == true ? Color(hex: "6BCB9A") : Color(hex: "E5B86B")
    }

    @ViewBuilder
    private func openWorkSection(_ workItems: [GitHubOpenWorkItem]) -> some View {
        if !workItems.isEmpty {
            VStack(alignment: .leading, spacing: 5) {
                Text("ÖPPET ARBETE")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(StudioTheme.muted)
                ForEach(workItems) { work in
                    Link(destination: work.htmlURL) {
                        HStack(spacing: 5) {
                            Image(systemName: work.symbol)
                            Text("\(work.kindLabel) #\(work.number) · \(work.title)")
                                .lineLimit(1)
                        }
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(StudioTheme.secondaryText)
                    }
                }
            }
            .padding(.top, 5)
        }
    }

    private var refreshButton: some View {
        Button {
            Task { await refresh() }
        } label: {
            Image(systemName: "arrow.clockwise")
                .font(.caption.weight(.semibold))
                .foregroundStyle(StudioTheme.accent)
                .padding(12)
        }
        .disabled(isLoading)
        .accessibilityLabel("Uppdatera aktivitetsflödet")
    }

    @MainActor
    private func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        defer {
            isLoading = false
            hasLoaded = true
        }

        var latest: [GitHubActivityItem] = []
        let service = GitHubRepositoryService()
        for project in projects where !project.repository.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            do {
                let result = try await service.fetchSnapshot(repository: project.repository)
                let workflow = try? await service.fetchLatestWorkflowRun(repository: project.repository)
                let openWorkItems = (try? await service.fetchOpenWorkItems(repository: project.repository)) ?? []
                let workflowSucceeded = workflow?.conclusion == "success"
                let workflowLabel = workflow.map { run in
                    if run.status != "completed" { return "Actions körs" }
                    return run.conclusion == "success" ? "Actions OK" : "Actions: \(run.conclusion ?? "okänt")"
                }
                let activity = GitHubActivityItem(
                    id: project.id,
                    projectName: project.name,
                    repositoryURL: result.0.htmlURL,
                    commitURL: result.1?.htmlURL,
                    message: result.1?.commit.message.components(separatedBy: .newlines).first,
                    pushedAt: result.0.pushedAt,
                    workflowLabel: workflowLabel,
                    workflowURL: workflow?.htmlURL,
                    workflowSucceeded: workflow == nil ? nil : workflowSucceeded,
                    openWorkItems: openWorkItems
                )
                latest.append(activity)
            } catch {
                continue
            }
        }
        items = latest.sorted {
            ($0.pushedAt ?? .distantPast) > ($1.pushedAt ?? .distantPast)
        }
    }
}
