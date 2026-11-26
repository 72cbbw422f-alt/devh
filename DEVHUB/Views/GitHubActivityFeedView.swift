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
    let dataWarnings: [String]
}

struct GitHubActivityFeedView: View {
    let projects: [StudioProject]
    @State private var items: [GitHubActivityItem] = []
    @State private var isLoading = false
    @State private var hasLoaded = false
    @State private var failedProjects: [String] = []

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
        } else if items.isEmpty && !failedProjects.isEmpty {
            failedEmptyState
        } else if items.isEmpty {
            emptyState
        } else {
            VStack(spacing: 0) {
                if !failedProjects.isEmpty {
                    failureNotice
                }
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

    private var failureNotice: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color(hex: "E5B86B"))
            VStack(alignment: .leading, spacing: 3) {
                Text("Viss GitHub-data kunde inte hämtas")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(StudioTheme.text)
                Text(failedProjects.joined(separator: ", "))
                    .font(.caption2)
                    .foregroundStyle(StudioTheme.muted)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(StudioTheme.elevated.opacity(0.7), in: RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 15)
        .padding(.top, 12)
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

    private var failedEmptyState: some View {
        VStack(alignment: .leading, spacing: 10) {
            failureNotice
            VStack(spacing: 8) {
                Image(systemName: "arrow.triangle.branch")
                    .font(.title2).foregroundStyle(StudioTheme.accent)
                Text("Ingen GitHub-data kunde visas")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(StudioTheme.text)
                Text("Kontrollera repository-adresserna och nätverksanslutningen och försök igen.")
                    .font(.caption).foregroundStyle(StudioTheme.muted)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(12)
        }
        .padding(.bottom, 8)
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
                dataWarningSection(item.dataWarnings)
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
    private func dataWarningSection(_ warnings: [String]) -> some View {
        if !warnings.isEmpty {
            HStack(alignment: .top, spacing: 5) {
                Image(systemName: "exclamationmark.circle")
                Text(warnings.joined(separator: " · "))
                    .lineLimit(2)
            }
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(Color(hex: "E5B86B"))
            .padding(.top, 3)
        }
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
                        HStack(spacing: 6) {
                            Image(systemName: work.symbol)
                            Text("\(work.kindLabel) #\(work.number) · \(work.title)")
                                .lineLimit(1)
                            Spacer(minLength: 4)
                            Text(work.updatedAt, style: .relative)
                                .font(.system(size: 8, weight: .regular))
                                .foregroundStyle(StudioTheme.muted)
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
        failedProjects = []
        let service = GitHubRepositoryService()
        for project in projects where !project.repository.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            do {
                let result = try await service.fetchSnapshot(repository: project.repository)
                var warnings: [String] = []
                let workflow: GitHubWorkflowRunSnapshot?
                do {
                    workflow = try await service.fetchLatestWorkflowRun(repository: project.repository)
                } catch {
                    workflow = nil
                    warnings.append("Actions kunde inte hämtas")
                }
                let openWorkItems: [GitHubOpenWorkItem]
                do {
                    openWorkItems = try await service.fetchOpenWorkItems(repository: project.repository)
                } catch {
                    openWorkItems = []
                    warnings.append("Issues/PR kunde inte hämtas")
                }
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
                    openWorkItems: openWorkItems,
                    dataWarnings: warnings
                )
                latest.append(activity)
            } catch {
                failedProjects.append(project.name)
                continue
            }
        }
        items = latest.sorted {
            ($0.pushedAt ?? .distantPast) > ($1.pushedAt ?? .distantPast)
        }
    }
}
