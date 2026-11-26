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
    let name: String?
    let htmlURL: URL
    let status: String
    let conclusion: String?
    enum CodingKeys: String, CodingKey {
        case name
        case htmlURL = "html_url"
        case status
        case conclusion
    }
}

enum GitHubRepositoryError: LocalizedError {
    case invalidRepository
    case notFound
    case rateLimited
    case requestFailed

    var errorDescription: String? {
        switch self {
        case .invalidRepository: "Ange en giltig GitHub-adress i projektinställningarna."
        case .notFound: "Repositoryt kunde inte hittas eller är privat."
        case .rateLimited: "GitHub har tillfälligt begränsat antalet förfrågningar. Försök igen senare."
        case .requestFailed: "Kunde inte hämta information från GitHub."
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
    private var entries: [String: Entry] = [:]
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
}

struct GitHubRepositoryService {
    func fetchSnapshot(repository: String) async throws -> (GitHubRepositorySnapshot, GitHubCommitSnapshot?) {
        let path = normalizedPath(repository)
        let parts = path.split(separator: "/", omittingEmptySubsequences: false)
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.")
        guard parts.count == 2, parts.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." && $0.unicodeScalars.allSatisfy(allowed.contains) }) else {
            throw GitHubRepositoryError.invalidRepository
        }

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

    func fetchLatestWorkflowRun(repository: String) async throws -> GitHubWorkflowRunSnapshot? {
        let path = normalizedPath(repository)
        let parts = path.split(separator: "/", omittingEmptySubsequences: false)
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_\.")
        guard parts.count == 2, parts.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." && $0.unicodeScalars.allSatisfy(allowed.contains) }) else {
            throw GitHubRepositoryError.invalidRepository
        }
        let url = URL(string: "https://api.github.com/repos/\(path)/actions/runs?per_page=1")!
        let response: WorkflowRunsResponse = try await request(url)
        return response.workflowRuns.first
    }

    private struct WorkflowRunsResponse: Decodable {
        let workflowRuns: [GitHubWorkflowRunSnapshot]
        enum CodingKeys: String, CodingKey {
            case workflowRuns = "workflow_runs"
        }
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
