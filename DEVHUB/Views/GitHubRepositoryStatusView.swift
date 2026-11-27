import SwiftUI

struct GitHubRepositoryStatusView: View {
    let repository: String
    @State private var snapshot: GitHubRepositorySnapshot?
    @State private var latestCommit: GitHubCommitSnapshot?
    @State private var errorMessage: String?
    @State private var isLoading = false

    private var repositoryPath: String {
        if repository.contains("/") { return repository }
        return "72cbbw422f-alt/\(repository)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeading(eyebrow: "LIVE FRÅN GITHUB", title: "Repositorystatus")
                Spacer()
                if isLoading {
                    ProgressView().tint(StudioTheme.accent)
                } else {
                    Button { Task { await refresh() } } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.subheadline.weight(.semibold))
                    }
                    .tint(StudioTheme.accent)
                    .accessibilityLabel("Uppdatera GitHub-status")
                }
            }

            if let snapshot {
                HStack(spacing: 7) {
                    Circle().fill(Color(hex: "6BCB9A")).frame(width: 7, height: 7)
                    Text("Tillgängligt").font(.caption.weight(.semibold)).foregroundStyle(Color(hex: "6BCB9A"))
                    Spacer()
                    Text(snapshot.defaultBranch).font(.caption.monospaced()).foregroundStyle(StudioTheme.muted)
                }
                HStack(spacing: 0) {
                    metric("\(snapshot.openIssuesCount)", label: "Öppna issues", symbol: "exclamationmark.circle")
                    Spacer()
                    metric("\(snapshot.stargazersCount)", label: "Stjärnor", symbol: "star")
                    Spacer()
                    metric("\(snapshot.forksCount)", label: "Forks", symbol: "tuningfork")
                }
                if let pushedAt = snapshot.pushedAt {
                    Text("Senast push: \(pushedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption).foregroundStyle(StudioTheme.muted)
                }
                if let latestCommit {
                    Divider().overlay(StudioTheme.border)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("SENASTE COMMIT").font(.system(size: 9, weight: .bold)).tracking(1).foregroundStyle(StudioTheme.muted)
                        Text(latestCommit.commit.message.components(separatedBy: .newlines).first ?? latestCommit.commit.message)
                            .font(.caption.weight(.medium)).foregroundStyle(StudioTheme.text).lineLimit(2)
                        if let author = latestCommit.commit.author?.name, !author.isEmpty {
                            Label(author, systemImage: "person")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(StudioTheme.muted)
                        }
                        Link("Visa commit", destination: latestCommit.htmlURL)
                            .font(.caption.weight(.semibold)).tint(StudioTheme.accent)
                    }
                }
                Link("Öppna \(snapshot.fullName)", destination: snapshot.htmlURL)
                    .font(.caption.weight(.semibold)).tint(StudioTheme.accent)
            } else if let errorMessage {
                Text(errorMessage).font(.caption).foregroundStyle(StudioTheme.muted)
                Button("Försök igen") { Task { await refresh() } }
                    .font(.caption.weight(.semibold)).tint(StudioTheme.accent)
            } else {
                Text("Hämtar repositoryinformation…")
                    .font(.caption).foregroundStyle(StudioTheme.muted)
            }
        }
        .padding(16)
        .background(StudioTheme.surface, in: RoundedRectangle(cornerRadius: 17))
        .overlay(RoundedRectangle(cornerRadius: 17).stroke(StudioTheme.border, lineWidth: 1))
        .task { await refresh() }
    }

    private func metric(_ value: String, label: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(value, systemImage: symbol)
                .font(.subheadline.weight(.bold)).foregroundStyle(StudioTheme.text)
            Text(label).font(.system(size: 9)).foregroundStyle(StudioTheme.muted)
        }
    }

    @MainActor
    private func refresh() async {
        guard !repository.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Inget repository är kopplat till projektet."
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let result = try await GitHubRepositoryService().fetchSnapshot(repository: repositoryPath)
            snapshot = result.0
            latestCommit = result.1
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
