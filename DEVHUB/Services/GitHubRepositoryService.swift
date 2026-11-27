import Foundation

struct GitHubRepositorySnapshot: Decodable, Sendable {
    let fullName: String
    let htmlURL: URL
    let defaultBranch: String
    let openIssuesCount: Int
    let stargazersCount: Int
    let forksCount: Int
    let pushedAt: Date?

    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
        case htmlURL = "html_url"
        case defaultBranch = "default_branch"
        case openIssuesCount = "open_issues_count"
        case stargazersCount = "stargazers_count"
        case forksCount = "forks_count"
        case pushedAt = "pushed_at"
    }
}

struct GitHubCommitSnapshot: Decodable, Sendable {
    struct Commit: Decodable, Sendable {
        let message: String
    }
    let htmlURL: URL
    let commit: Commit

    enum CodingKeys: String, CodingKey {
        case htmlURL = "html_url"
        case commit
    }
}

struct GitHubWorkflowRunSnapshot: Decodable, Sendable {
    let id: Int
    let name: String?
    let htmlURL: URL
    let status: String
    let conclusion: String?
    enum CodingKeys: String, CodingKey {
        case id, name
        case htmlURL = "html_url"
        case status
        case conclusion
    }
}


struct GitHubOpenWorkItem: Decodable, Identifiable, Sendable {
    struct PullRequestLink: Decodable, Sendable {
        let url: URL?
        enum CodingKeys: String, CodingKey { case url = "html_url" }
    }

    let number: Int
    let title: String
    let htmlURL: URL
    let updatedAt: Date
    let pullRequest: PullRequestLink?

    var id: Int { number }
    var kindLabel: String { pullRequest == nil ? "Issue" : "PR" }
    var symbol: String { pullRequest == nil ? "exclamationmark.circle" : "arrow.triangle.pull" }

    enum CodingKeys: String, CodingKey {
        case number, title
        case htmlURL = "html_url"
        case updatedAt = "updated_at"
        case pullRequest = "pull_request"
    }
}


struct GitHubPullRequestVerification: Sendable {
    let pullRequestURL: URL
    let commitSHA: String
    let workflowURL: URL
}

private struct GitHubPullRequestSnapshot: Decodable {
    struct Head: Decodable { let sha: String }
    let htmlURL: URL
    let merged: Bool
    let head: Head
    enum CodingKeys: String, CodingKey {
        case htmlURL = "html_url"
        case merged, head
    }
}

private struct GitHubCombinedStatus: Decodable {
    let state: String
    let totalCount: Int
    enum CodingKeys: String, CodingKey { case state; case totalCount = "total_count" }
}

private struct GitHubCheckRunsResponse: Decodable {
    struct CheckRun: Decodable {
        let status: String
        let conclusion: String?
        let htmlURL: URL?
        enum CodingKeys: String, CodingKey {
            case status, conclusion
            case htmlURL = "html_url"
        }
    }
    let checkRuns: [CheckRun]
    let totalCount: Int
    enum CodingKeys: String, CodingKey {
        case checkRuns = "check_runs"
        case totalCount = "total_count"
    }
}

enum GitHubRepositoryError: LocalizedError {
    case invalidRepository
    case notFound
    case rateLimited
    case requestFailed
    case pullRequestNotMerged
    case checksNotSuccessful
    case invalidPullRequest

    var errorDescription: String? {
        switch self {
        case .invalidRepository: "Ange en giltig GitHub-adress i projektinställningarna."
        case .notFound: "Repositoryt kunde inte hittas eller är privat."
        case .rateLimited: "GitHub har tillfälligt begränsat antalet förfrågningar. Försök igen senare."
        case .requestFailed: "Kunde inte hämta information från GitHub."
        case .pullRequestNotMerged: "Pull requesten är inte mergad ännu."
        case .checksNotSuccessful: "Alla GitHub-kontroller måste vara klara och godkända innan uppgiften kan verifieras."
        case .invalidPullRequest: "Ange en giltig GitHub PR-länk till projektets repository."
        }
    }
}

private struct CachedGitHubRepository: Sendable {
    let snapshot: GitHubRepositorySnapshot
    let latestCommit: GitHubCommitSnapshot?
}

private actor GitHubRepositoryCache {
    static let shared = GitHubRepositoryCache()

    private struct Entry {
        let value: CachedGitHubRepository
        let savedAt: Date
    }
    private struct WorkItemsEntry {
        let value: [GitHubOpenWorkItem]
        let savedAt: Date
    }
    private struct WorkflowEntry {
        let value: GitHubWorkflowRunSnapshot?
        let savedAt: Date
    }

    private var entries: [String: Entry] = [:]
    private var workflowEntries: [String: WorkflowEntry] = [:]
    private var workItemsEntries: [String: WorkItemsEntry] = [:]
    private let lifetime: TimeInterval = 300

    func value(for key: String) -> CachedGitHubRepository? {
        guard let entry = entries[key],
              Date().timeIntervalSince(entry.savedAt) < lifetime else {
            entries.removeValue(forKey: key)
            return nil
        }
        return entry.value
    }

    func store(_ value: CachedGitHubRepository, for key: String) {
        entries[key] = Entry(value: value, savedAt: Date())
    }

    func workItemsValue(for key: String) -> [GitHubOpenWorkItem]? {
        guard let entry = workItemsEntries[key],
              Date().timeIntervalSince(entry.savedAt) < lifetime else {
            workItemsEntries.removeValue(forKey: key)
            return nil
        }
        return entry.value
    }

    func storeWorkItems(_ value: [GitHubOpenWorkItem], for key: String) {
        workItemsEntries[key] = WorkItemsEntry(value: value, savedAt: Date())
    }

    func workflowValue(for key: String) -> GitHubWorkflowRunSnapshot?? {
        guard let entry = workflowEntries[key],
              Date().timeIntervalSince(entry.savedAt) < lifetime else {
            workflowEntries.removeValue(forKey: key)
            return nil
        }
        return .some(entry.value)
    }

    func storeWorkflow(_ value: GitHubWorkflowRunSnapshot?, for key: String) {
        workflowEntries[key] = WorkflowEntry(value: value, savedAt: Date())
    }
}

struct GitHubRepositoryService {

    func verifyMergedPullRequest(url rawURL: String, expectedRepository: String) async throws -> GitHubPullRequestVerification {
        guard let url = URL(string: rawURL.trimmingCharacters(in: .whitespacesAndNewlines)),
              url.scheme == "https", url.host == "github.com" else {
            throw GitHubRepositoryError.invalidPullRequest
        }
        let parts = url.path.split(separator: "/")
        guard parts.count == 4, parts[2] == "pull", let number = Int(parts[3]) else {
            throw GitHubRepositoryError.invalidPullRequest
        }
        let repositoryPath = "\(parts[0])/\(parts[1])"
        let expectedPath = try validatedPath(expectedRepository)
        guard repositoryPath.caseInsensitiveCompare(expectedPath) == .orderedSame else {
            throw GitHubRepositoryError.invalidPullRequest
        }

        let prURL = URL(string: "https://api.github.com/repos/\(repositoryPath)/pulls/\(number)")!
        let pullRequest: GitHubPullRequestSnapshot = try await request(prURL)
        guard pullRequest.merged else { throw GitHubRepositoryError.pullRequestNotMerged }

        let checksURL = URL(string: "https://api.github.com/repos/\(repositoryPath)/commits/\(pullRequest.head.sha)/check-runs?per_page=100")!
        let checks: GitHubCheckRunsResponse = try await request(checksURL)
        guard !checks.checkRuns.isEmpty,
              checks.totalCount == checks.checkRuns.count,
              checks.checkRuns.allSatisfy({ $0.status == "completed" && $0.conclusion == "success" }) else {
            throw GitHubRepositoryError.checksNotSuccessful
        }
        let statusURL = URL(string: "https://api.github.com/repos/\(repositoryPath)/commits/\(pullRequest.head.sha)/status")!
        let combinedStatus: GitHubCombinedStatus = try await request(statusURL)
        guard combinedStatus.state == "success" else {
            throw GitHubRepositoryError.checksNotSuccessful
        }
        let workflowURL = checks.checkRuns.compactMap { $0.htmlURL }.first ?? pullRequest.htmlURL
        return GitHubPullRequestVerification(pullRequestURL: pullRequest.htmlURL, commitSHA: pullRequest.head.sha, workflowURL: workflowURL)
    }

    func fetchSnapshot(repository: String) async throws -> (GitHubRepositorySnapshot, GitHubCommitSnapshot?) {
        let path = try validatedPath(repository)

        if let cached = await GitHubRepositoryCache.shared.value(for: path) {
            return (cached.snapshot, cached.latestCommit)
        }

        let repoURL = URL(string: "https://api.github.com/repos/\(path)")!
        let snapshot: GitHubRepositorySnapshot = try await request(repoURL)

        let commitsURL = URL(string: "https://api.github.com/repos/\(path)/commits?per_page=1")!
        let commits: [GitHubCommitSnapshot]? = try? await request(commitsURL)
        let result = CachedGitHubRepository(snapshot: snapshot, latestCommit: commits?.first)
        await GitHubRepositoryCache.shared.store(result, for: path)
        return (result.snapshot, result.latestCommit)
    }


    func fetchOpenWorkItems(repository: String) async throws -> [GitHubOpenWorkItem] {
        let path = try validatedPath(repository)
        if let cached = await GitHubRepositoryCache.shared.workItemsValue(for: path) {
            return cached
        }
        let url = URL(string: "https://api.github.com/repos/\(path)/issues?state=open&sort=updated&direction=desc&per_page=4")!
        let items: [GitHubOpenWorkItem] = try await request(url)
        await GitHubRepositoryCache.shared.storeWorkItems(items, for: path)
        return items
    }

    func fetchLatestWorkflowRun(repository: String) async throws -> GitHubWorkflowRunSnapshot? {
        let path = try validatedPath(repository)
        if let cached = await GitHubRepositoryCache.shared.workflowValue(for: path) {
            return cached
        }

        let url = URL(string: "https://api.github.com/repos/\(path)/actions/runs?per_page=1")!
        let response: WorkflowRunsResponse = try await request(url)
        let latest = response.workflowRuns.first
        await GitHubRepositoryCache.shared.storeWorkflow(latest, for: path)
        return latest
    }

    private struct WorkflowRunsResponse: Decodable {
        let workflowRuns: [GitHubWorkflowRunSnapshot]
        enum CodingKeys: String, CodingKey {
            case workflowRuns = "workflow_runs"
        }
    }

    private func validatedPath(_ repository: String) throws -> String {
        let path = normalizedPath(repository)
        let parts = path.split(separator: "/", omittingEmptySubsequences: false)
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.")
        guard parts.count == 2,
              parts.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." && $0.unicodeScalars.allSatisfy(allowed.contains) }) else {
            throw GitHubRepositoryError.invalidRepository
        }
        return path
    }

    private func normalizedPath(_ repository: String) -> String {
        var value = repository.trimmingCharacters(in: .whitespacesAndNewlines)
        value = value.replacingOccurrences(of: "https://github.com/", with: "")
        value = value.replacingOccurrences(of: "http://github.com/", with: "")
        if value.hasSuffix(".git") { value.removeLast(4) }
        value = value.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if !value.contains("/") { value = "72cbbw422f-alt/\(value)" }
        return value
    }

    private func request<T: Decodable>(_ url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("DEVHUB-iOS", forHTTPHeaderField: "User-Agent")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw GitHubRepositoryError.requestFailed
        }
        switch response.statusCode {
        case 200...299:
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        case 403, 429: throw GitHubRepositoryError.rateLimited
        case 404: throw GitHubRepositoryError.notFound
        default: throw GitHubRepositoryError.requestFailed
        }
    }
}
