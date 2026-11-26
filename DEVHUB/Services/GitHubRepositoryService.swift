import Foundation

struct GitHubRepositorySnapshot: Decodable {
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

struct GitHubCommitSnapshot: Decodable {
    struct Commit: Decodable {
        let message: String
    }
    let htmlURL: URL
    let commit: Commit

    enum CodingKeys: String, CodingKey {
        case htmlURL = "html_url"
        case commit
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

struct GitHubRepositoryService {
    func fetchSnapshot(repository: String) async throws -> (GitHubRepositorySnapshot, GitHubCommitSnapshot?) {
        let path = normalizedPath(repository)
        let parts = path.split(separator: "/", omittingEmptySubsequences: false)
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.")
        guard parts.count == 2, parts.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." && $0.unicodeScalars.allSatisfy(allowed.contains) }) else {
            throw GitHubRepositoryError.invalidRepository
        }

        let repoURL = URL(string: "https://api.github.com/repos/\(path)")!
        let snapshot: GitHubRepositorySnapshot = try await request(repoURL)

        let commitsURL = URL(string: "https://api.github.com/repos/\(path)/commits?per_page=1")!
        let commits: [GitHubCommitSnapshot]? = try? await request(commitsURL)
        return (snapshot, commits?.first)
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
