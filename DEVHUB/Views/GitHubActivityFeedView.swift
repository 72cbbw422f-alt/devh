import SwiftUI
import SwiftData

private struct GitHubActivityItem: Identifiable {
    let id: String
    let projectName: String
    let repositoryURL: URL
    let commitURL: URL?
    let message: String?
    let commitAuthor: String?
    let pushedAt: Date?
    let workflowLabel: String?
    let workflowURL: URL?
    let workflowSucceeded: Bool?
    let openWorkItems: [GitHubOpenWorkItem]
    let dataWarnings: [String]
}

struct GitHubActivityFeedView: View {
    let projects: [StudioProject]
    @Environment(\.modelContext) private var modelContext
    @AppStorage("github.activity.seenKeys") private var seenKeysStorage = ""
    @AppStorage("github.activity.hasBaseline") private var hasActivityBaseline = false
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
                if let author = item.commitAuthor, !author.isEmpty {
                    Label("Commit av \(author)", systemImage: "person")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(StudioTheme.muted)
                        .lineLimit(1)
                }
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
        if item.workflowSucceeded == true { return "checkmark.circle.fill" }
        guard let label = item.workflowLabel else { return "questionmark.circle" }
        if label.contains("pågår") { return "arrow.triangle.2.circlepath" }
        if label.contains("köad") { return "clock" }
        if label.contains("misslyckad") || label.contains("timeout") { return "xmark.circle.fill" }
        if label.contains("avbruten") || label.contains("hoppad") { return "minus.circle" }
        return "exclamationmark.circle.fill"
    }

    private func workflowColor(_ item: GitHubActivityItem) -> Color {
        if item.workflowSucceeded == true { return Color(hex: "6BCB9A") }
        guard let label = item.workflowLabel else { return StudioTheme.muted }
        if label.contains("pågår") { return StudioTheme.accentCyan }
        if label.contains("köad") { return Color(hex: "E5B86B") }
        if label.contains("misslyckad") || label.contains("timeout") { return Color(hex: "E47777") }
        if label.contains("avbruten") || label.contains("hoppad") { return StudioTheme.muted }
        return Color(hex: "E5B86B")
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
        let pullRequests = workItems.filter { $0.pullRequest != nil }
        let issues = workItems.filter { $0.pullRequest == nil }

        if !pullRequests.isEmpty || !issues.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                if !pullRequests.isEmpty {
                    workItemGroup("PULL REQUESTS", items: pullRequests)
                }
                if !issues.isEmpty {
                    workItemGroup("ISSUES", items: issues)
                }
            }
            .padding(.top, 5)
        }
    }

    private func workItemGroup(_ title: String, items: [GitHubOpenWorkItem]) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 8, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(StudioTheme.muted)
            ForEach(items) { work in
                Link(destination: work.htmlURL) {
                    HStack(spacing: 6) {
                        Image(systemName: work.symbol)
                        Text("#\(work.number) · \(work.title)")
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
        var observedEventKeys: Set<String> = []
        failedProjects = []
        let service = GitHubRepositoryService()
        for project in projects where !project.repository.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            do {
                // Fetch the repository snapshot, latest Actions run and open
                // issues/PRs concurrently. Serial requests made the dashboard
                // wait for up to three network round-trips per project.
                async let snapshotRequest = service.fetchSnapshot(repository: project.repository)
                async let workflowRequest = service.fetchLatestWorkflowRun(repository: project.repository)
                async let workItemsRequest = service.fetchOpenWorkItems(repository: project.repository)

                let result = try await snapshotRequest
                var warnings: [String] = []
                let workflow: GitHubWorkflowRunSnapshot?
                do {
                    workflow = try await workflowRequest
                } catch {
                    workflow = nil
                    warnings.append("Actions kunde inte hämtas")
                }
                let openWorkItems: [GitHubOpenWorkItem]
                do {
                    openWorkItems = try await workItemsRequest
                } catch {
                    openWorkItems = []
                    warnings.append("Issues/PR kunde inte hämtas")
                }
                if let workflow, workflow.status == "completed" {
                    observedEventKeys.insert("workflow|\(project.repository)|\(workflow.id)|\(workflow.conclusion ?? "unknown")")
                }
                for work in openWorkItems {
                    observedEventKeys.insert("work|\(project.repository)|\(work.number)|\(work.updatedAt.timeIntervalSince1970)")
                }
                let workflowSucceeded = workflow?.conclusion == "success"
                let workflowLabel = workflow.map { run in
                    switch run.status {
                    case "queued", "requested", "waiting": return "Actions köad"
                    case "in_progress": return "Actions pågår"
                    case "completed":
                        switch run.conclusion {
                        case "success": return "Actions godkänd"
                        case "failure": return "Actions misslyckad"
                        case "cancelled": return "Actions avbruten"
                        case "timed_out": return "Actions timeout"
                        case "skipped": return "Actions hoppad över"
                        default: return "Actions: \(run.conclusion ?? "okänt")"
                        }
                    default: return "Actions: \(run.status)"
                    }
                }
                let activity = GitHubActivityItem(
                    id: project.id,
                    projectName: project.name,
                    repositoryURL: result.0.htmlURL,
                    commitURL: result.1?.htmlURL,
                    message: result.1?.commit.message.components(separatedBy: .newlines).first,
                    commitAuthor: result.1?.commit.author?.name,
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
        let previousKeys = Set(seenKeysStorage.split(separator: "\n").map(String.init))
        if !hasActivityBaseline {
            // First successful scan establishes a baseline; it must not alert on old activity.
            seenKeysStorage = observedEventKeys.sorted().joined(separator: "\n")
            hasActivityBaseline = true
        } else {
            let newKeys = observedEventKeys.subtracting(previousKeys)
            for key in newKeys {
                if key.hasPrefix("workflow|") {
                    let parts = key.split(separator: "|")
                    let repository = parts.count > 1 ? String(parts[1]) : "GitHub"
                    let conclusion = parts.count > 3 ? String(parts[3]) : "unknown"
                    let succeeded = conclusion == "success"
                    modelContext.insert(DEVHUBNotification(
                        title: succeeded ? "Ny byggning lyckades" : "En byggning behöver kontrolleras",
                        message: "\(repository): GitHub Actions avslutades med resultatet \(conclusion).",
                        category: succeeded ? "build" : "issue",
                        sourceKey: key,
                        destinationURL: latest.first(where: { $0.repositoryURL.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")) == repository })?.workflowURL?.absoluteString
                    ))
                } else if key.hasPrefix("work|") {
                    let parts = key.split(separator: "|")
                    let repository = parts.count > 1 ? String(parts[1]) : "GitHub"
                    let number = parts.count > 2 ? String(parts[2]) : "?"
                    let project = latest.first(where: { $0.repositoryURL.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")) == repository })
                    let work = project?.openWorkItems.first { String($0.number) == number }
                    modelContext.insert(DEVHUBNotification(
                        title: work?.pullRequest == nil ? "Nytt eller uppdaterat issue" : "Ny eller uppdaterad pull request",
                        message: "\(repository) #\(number) · \(work?.title ?? "Öppna ärendet i GitHub för detaljer.")",
                        category: "issue",
                        sourceKey: key,
                        destinationURL: work?.htmlURL.absoluteString
                    ))
                }
            }
            let merged = previousKeys.union(observedEventKeys)
            // Keep storage bounded while retaining enough history to prevent repeat alerts.
            seenKeysStorage = merged.sorted().suffix(500).joined(separator: "\n")
        }
        items = latest.sorted {
            ($0.pushedAt ?? .distantPast) > ($1.pushedAt ?? .distantPast)
        }
    }
}
