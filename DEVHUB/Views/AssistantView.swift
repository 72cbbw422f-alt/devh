import SwiftUI
import Security
import ZIPFoundation

private struct AssistantRepository: Identifiable {
    let name: String
    let fullName: String
    var id: String { fullName }
}

struct AssistantView: View {
    @State private var selectedRepository = "72cbbw422f-alt/project-orbit"
    @State private var task = ""
    @State private var githubToken = ""
    @State private var hasSavedToken = false
    @State private var isSending = false
    @State private var statusMessage: String?
    @State private var workflowURL: URL?
    @State private var runStatus: String?
    @State private var analysisText: String?
    @FocusState private var focusedField: AssistantInput?

    private enum AssistantInput: Hashable { case token, task }

    private let repositories: [AssistantRepository] = [
        .init(name: "Regnvakt", fullName: "72cbbw422f-alt/project-orbit"),
        .init(name: "Familjen", fullName: "72cbbw422f-alt/fam"),
        .init(name: "Watchlist", fullName: "72cbbw422f-alt/binge"),
        .init(name: "Antikspanaren", fullName: "72cbbw422f-alt/vill"),
        .init(name: "Hemma", fullName: "72cbbw422f-alt/hem"),
        .init(name: "DEVHUB", fullName: "72cbbw422f-alt/devh")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("DEVHUB AI", systemImage: "sparkles")
                        .font(.caption.bold()).foregroundStyle(StudioTheme.accent)
                    Text("Vad ska vi bygga idag?")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(StudioTheme.text)
                    Text("Välj ett av dina sex projekt och ge assistenten en uppgift.")
                        .font(.subheadline).foregroundStyle(StudioTheme.secondaryText)
                }
                connectionCard
                requestCard
                if let statusMessage {
                    Text(statusMessage)
                        .font(.subheadline)
                        .foregroundStyle(StudioTheme.secondaryText)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(StudioTheme.elevated, in: RoundedRectangle(cornerRadius: 12))
                }
                if let runStatus {
                    HStack(spacing: 9) {
                        Image(systemName: runStatus.contains("lyckades") ? "checkmark.circle.fill" : "clock.arrow.circlepath")
                            .foregroundStyle(runStatus.contains("lyckades") ? .green : StudioTheme.accent)
                        Text(runStatus).font(.subheadline).foregroundStyle(StudioTheme.text)
                    }
                    .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                    .background(StudioTheme.elevated, in: RoundedRectangle(cornerRadius: 12))
                }
                if let analysisText {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("AI-resultat", systemImage: "sparkles")
                            .font(.headline).foregroundStyle(StudioTheme.text)
                        Group {
                            if let formatted = try? AttributedString(markdown: analysisText) {
                                Text(formatted)
                            } else {
                                Text(analysisText)
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(StudioTheme.secondaryText)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(15)
                    .background(StudioTheme.surface, in: RoundedRectangle(cornerRadius: 15))
                    .overlay(RoundedRectangle(cornerRadius: 15).stroke(StudioTheme.border, lineWidth: 1))
                }
                if let workflowURL {
                    Link(destination: workflowURL) {
                        Label("Öppna AI-körningen i GitHub", systemImage: "arrow.up.right.square")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity).padding(14)
                            .background(StudioTheme.accent, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }
                }
                Text("Första versionen analyserar projektet utan att ändra kod. Skrivbehörighet och pull requests lägger vi till separat med godkännande.")
                    .font(.caption).foregroundStyle(StudioTheme.muted)
            }
            .padding(18).frame(maxWidth: 760).frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(StudioTheme.background.ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Klar") { focusedField = nil }
            }
        }
        .navigationTitle("Assistent")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let token = GitHubTokenStore.read() {
                githubToken = token
                hasSavedToken = true
            }
        }
    }

    private var connectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("GitHub-anslutning", systemImage: "lock.shield")
                .font(.headline).foregroundStyle(StudioTheme.text)
            SecureField("Fine-grained GitHub-token", text: $githubToken)
                .focused($focusedField, equals: .token)
                .submitLabel(.done)
                .onSubmit { focusedField = nil }
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textContentType(.password)
                .foregroundStyle(StudioTheme.text)
                .tint(StudioTheme.accent)
                .padding(12)
                .background(StudioTheme.elevated, in: RoundedRectangle(cornerRadius: 10))
            HStack {
                Text(hasSavedToken ? "Token sparad i nyckelringen" : "Sparas säkert i iPhones nyckelring")
                    .font(.caption).foregroundStyle(StudioTheme.muted)
                Spacer()
                Button("Spara") {
                    do {
                        try GitHubTokenStore.save(githubToken)
                        hasSavedToken = true
                        statusMessage = "GitHub-token sparad på enheten."
                    } catch {
                        statusMessage = error.localizedDescription
                    }
                }
                .font(.subheadline.weight(.semibold))
                .disabled(githubToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            Link("Skapa token på GitHub", destination: URL(string: "https://github.com/settings/personal-access-tokens")!)
                .font(.caption.weight(.medium))
            Text("Token ska endast ha åtkomst till devh och behörigheten Actions: Read and write.")
                .font(.caption).foregroundStyle(StudioTheme.secondaryText)
        }
        .padding(15).frame(maxWidth: .infinity, alignment: .leading)
        .background(StudioTheme.surface, in: RoundedRectangle(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(StudioTheme.border, lineWidth: 1))
    }

    private var requestCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nytt uppdrag").font(.headline).foregroundStyle(StudioTheme.text)
            Picker("Projekt", selection: $selectedRepository) {
                ForEach(repositories) { project in
                    Text(project.name).tag(project.fullName)
                }
            }
            .pickerStyle(.menu).tint(StudioTheme.accent)
            TextField(
                "Vad vill du att AI:n ska undersöka?",
                text: $task,
                prompt: Text("Beskriv uppdraget…").foregroundColor(StudioTheme.muted),
                axis: .vertical
            )
                .focused($focusedField, equals: .task)
                .submitLabel(.send)
                .onSubmit { submitTask() }
                .lineLimit(4...7)
                .foregroundStyle(StudioTheme.text)
                .tint(StudioTheme.accent)
                .padding(12)
                .background(StudioTheme.elevated, in: RoundedRectangle(cornerRadius: 10))
            Button(action: submitTask) {
                HStack {
                    if isSending { ProgressView().tint(.white) }
                    else { Image(systemName: "paperplane.fill") }
                    Text(isSending ? "Startar analys…" : "Skicka till AI-assistenten")
                }
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity).padding(14)
                .background(StudioTheme.accent, in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.white)
            }
            .disabled(isSending || task.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !hasSavedToken)
            if !hasSavedToken {
                Text("Spara GitHub-token först för att aktivera assistenten.")
                    .font(.caption).foregroundStyle(StudioTheme.muted)
            }
        }
        .padding(15).frame(maxWidth: .infinity, alignment: .leading)
        .background(StudioTheme.surface, in: RoundedRectangle(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(StudioTheme.border, lineWidth: 1))
    }

    private func submitTask() {
        guard let token = GitHubTokenStore.read() else {
            statusMessage = "GitHub-token saknas. Spara den först."
            return
        }
        let prompt = task.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }
        focusedField = nil
        isSending = true
        statusMessage = nil
        workflowURL = nil
        analysisText = nil
        runStatus = "Skickar uppdraget till GitHub…"
        let startedAt = Date()
        Task {
            do {
                try await GitHubWorkflowClient.dispatch(repository: selectedRepository, task: prompt, token: token)
                await MainActor.run { statusMessage = "Uppdraget är mottaget. Väntar på AI-analysen…"; task = "" }
                let result = try await GitHubWorkflowClient.waitForRun(startedAt: startedAt, token: token)
                await MainActor.run {
                    isSending = false
                    runStatus = result.message
                    workflowURL = result.url
                }
                if result.message.contains("lyckades") {
                    do {
                        let text = try await GitHubWorkflowClient.fetchAnalysis(runID: result.id, token: token)
                        await MainActor.run {
                            analysisText = text
                            statusMessage = nil
                        }
                    } catch {
                        await MainActor.run { statusMessage = error.localizedDescription }
                    }
                }
            } catch {
                await MainActor.run {
                    isSending = false
                    statusMessage = error.localizedDescription
                    runStatus = "Kunde inte bekräfta att AI-körningen blev klar."
                }
            }
        }
    }
}

private enum GitHubTokenStore {
    private static let service = "se.niklas.devhub.github"
    private static let account = "workflow-token"

    static func read() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func save(_ token: String) throws {
        let data = Data(token.trimmingCharacters(in: .whitespacesAndNewlines).utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if status == errSecItemNotFound {
            var insert = query
            insert[kSecValueData as String] = data
            let addStatus = SecItemAdd(insert as CFDictionary, nil)
            guard addStatus == errSecSuccess else { throw TokenStoreError.keychain(addStatus) }
        } else if status != errSecSuccess {
            throw TokenStoreError.keychain(status)
        }
    }

    private enum TokenStoreError: LocalizedError {
        case keychain(OSStatus)
        var errorDescription: String? {
            switch self {
            case .keychain(let status):
                return "Kunde inte spara GitHub-token i iOS-nyckelringen (felkod \(status))."
            }
        }
    }
}

private enum GitHubWorkflowClient {
    struct RunResult { let id: Int; let message: String; let url: URL? }
    private struct ArtifactsResponse: Decodable { let artifacts: [Artifact] }
    private struct Artifact: Decodable { let id: Int; let name: String }
    private struct RunsResponse: Decodable { let workflow_runs: [WorkflowRun] }
    private struct WorkflowRun: Decodable {
        let id: Int
        let status: String
        let conclusion: String?
        let html_url: String
        let created_at: String
        let event: String
    }

    static func waitForRun(startedAt: Date, token: String) async throws -> RunResult {
        let formatter = ISO8601DateFormatter()
        for _ in 0..<40 {
            try await Task.sleep(nanoseconds: 3_000_000_000)
            var request = URLRequest(url: URL(string: "https://api.github.com/repos/72cbbw422f-alt/devh/actions/workflows/ai-assistant.yml/runs?per_page=10")!)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { throw WorkflowError.statusCheck }
            let runs = try JSONDecoder().decode(RunsResponse.self, from: data).workflow_runs
            guard let run = runs.first(where: { $0.event == "workflow_dispatch" && (formatter.date(from: $0.created_at) ?? .distantPast) >= startedAt.addingTimeInterval(-10) }) else { continue }
            if run.status == "completed" {
                let message = run.conclusion == "success" ? "AI-analysen lyckades! Resultatet finns i GitHub-körningens Summary." : "AI-körningen avslutades med fel (\(run.conclusion ?? "okänt fel")). Öppna körningen för detaljer."
                return RunResult(id: run.id, message: message, url: URL(string: run.html_url))
            }
        }
        throw WorkflowError.timeout
    }


    static func fetchAnalysis(runID: Int, token: String) async throws -> String {
        let api = "https://api.github.com/repos/72cbbw422f-alt/devh/actions/runs/\(runID)/artifacts"
        var request = URLRequest(url: URL(string: api)!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        let (metadata, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { throw WorkflowError.artifactUnavailable }
        let artifacts = try JSONDecoder().decode(ArtifactsResponse.self, from: metadata).artifacts
        guard let artifact = artifacts.first(where: { $0.name == "devhub-ai-result" }) else { throw WorkflowError.artifactUnavailable }

        let downloadURL = URL(string: "https://api.github.com/repos/72cbbw422f-alt/devh/actions/artifacts/\(artifact.id)/zip")!
        var downloadRequest = URLRequest(url: downloadURL)
        downloadRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        downloadRequest.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        let (archiveData, downloadResponse) = try await URLSession.shared.data(for: downloadRequest)
        guard let downloadHTTP = downloadResponse as? HTTPURLResponse, downloadHTTP.statusCode == 200 else { throw WorkflowError.artifactUnavailable }

        let archiveURL = FileManager.default.temporaryDirectory.appendingPathComponent("devhub-ai-\(runID).zip")
        try archiveData.write(to: archiveURL, options: .atomic)
        defer { try? FileManager.default.removeItem(at: archiveURL) }
        guard let archive = Archive(url: archiveURL, accessMode: .read),
              let entry = archive["analysis.md"] else { throw WorkflowError.artifactUnreadable }
        var output = Data()
        _ = try archive.extract(entry) { output.append($0) }
        guard let result = String(data: output, encoding: .utf8), !result.isEmpty else { throw WorkflowError.artifactUnreadable }
        return result
    }

    static func dispatch(repository: String, task: String, token: String) async throws {
        let url = URL(string: "https://api.github.com/repos/72cbbw422f-alt/devh/actions/workflows/ai-assistant.yml/dispatches")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "ref": "main",
            "inputs": ["project_repository": repository, "task": task]
        ])
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw WorkflowError.invalidResponse }
        guard (200...299).contains(http.statusCode) else {
            let detail = String(data: data, encoding: .utf8) ?? ""
            if http.statusCode == 401 || http.statusCode == 403 { throw WorkflowError.permission }
            throw WorkflowError.http(http.statusCode, detail)
        }
    }

    private enum WorkflowError: LocalizedError {
        case invalidResponse, permission, statusCheck, timeout, artifactUnavailable, artifactUnreadable, http(Int, String)
        var errorDescription: String? {
            switch self {
            case .invalidResponse: return "GitHub returnerade ett ogiltigt svar."
            case .permission: return "GitHub nekade åtkomst. Kontrollera token och Actions: Read and write."
            case .statusCheck: return "Uppdraget skickades, men DEVHUB kunde inte läsa status från GitHub. Kontrollera tokenens Actions-behörighet."
            case .timeout: return "AI-körningen pågår fortfarande. DEVHUB slutade vänta efter två minuter. Öppna GitHub för att följa den."
            case .artifactUnavailable: return "AI-analysen blev klar, men resultatfilen kunde inte hämtas. Öppna körningen i GitHub."
            case .artifactUnreadable: return "AI-resultatet hämtades men kunde inte läsas."
            case .http(let code, let detail): return "GitHub-anropet misslyckades (HTTP \(code)): \(detail)"
            }
        }
    }
}
