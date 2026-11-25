import SwiftUI

struct AssistantView: View {
    @State private var selectedRepository = "72cbbw422f-alt/project-orbit"
    @State private var task = ""
    @State private var githubToken = ""
    @State private var hasSavedToken = false
    @State private var isSending = false
    @State private var statusMessage: String?
    @State private var workflowURL: URL?

    private let repositories: [(name: String, fullName: String)] = [
        ("Regnvakt", "72cbbw422f-alt/project-orbit"),
        ("VITAL", "72cbbw422f-alt/vit"),
        ("Familjen", "72cbbw422f-alt/fam"),
        ("Antikspanaren", "72cbbw422f-alt/vill"),
        ("BingeLog / Watchlist", "72cbbw422f-alt/binge"),
        ("NEWSFLOW", "72cbbw422f-alt/news"),
        ("NEXUS", "72cbbw422f-alt/nex"),
        ("ORBIT", "72cbbw422f-alt/orb")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                connectionCard
                requestCard
                if let statusMessage {
                    statusCard(statusMessage)
                }
                if let workflowURL {
                    Link(destination: workflowURL) {
                        Label("Öppna AI-körningen i GitHub", systemImage: "arrow.up.right.square")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(StudioTheme.accent, in: RoundedRectangle(cornerRadius: 13))
                            .foregroundStyle(.white)
                    }
                }
                Text("Första versionen analyserar kod utan att ändra något. Kodändringar kommer senare att ske på en separat branch och kräva ditt godkännande.")
                    .font(.caption)
                    .foregroundStyle(StudioTheme.muted)
                    .lineSpacing(3)
            }
            .padding(18)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(StudioTheme.background)
        .navigationTitle("Assistent")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let saved = GitHubTokenStore.read() {
                githubToken = saved
                hasSavedToken = true
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles").foregroundStyle(StudioTheme.accent)
                Text("DEVHUB AI").font(.system(size: 10, weight: .bold)).tracking(1.4).foregroundStyle(StudioTheme.muted)
            }
            Text("Vad ska vi bygga idag?")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(StudioTheme.text)
            Text("Välj projekt och ge assistenten en konkret uppgift.")
                .font(.subheadline)
                .foregroundStyle(StudioTheme.secondaryText)
        }
    }

    private var connectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("GitHub-anslutning", systemImage: "lock.shield")
                .font(.headline)
                .foregroundStyle(StudioTheme.text)
            SecureField("Fine-grained GitHub-token", text: $githubToken)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textContentType(.password)
                .padding(12)
                .background(StudioTheme.elevated, in: RoundedRectangle(cornerRadius: 10))
            HStack {
                Text(hasSavedToken ? "Token sparad säkert på enheten" : "Token sparas i iOS-nyckelringen")
                    .font(.caption)
                    .foregroundStyle(StudioTheme.muted)
                Spacer()
                Button("Spara") {
                    do {
                        try GitHubTokenStore.save(githubToken)
                        hasSavedToken = true
                        statusMessage = "GitHub-token sparad i iOS-nyckelringen."
                    } catch {
                        statusMessage = error.localizedDescription
                    }
                }
                .font(.subheadline.weight(.semibold))
                .disabled(githubToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            Link("Skapa en fine-grained token på GitHub", destination: URL(string: "https://github.com/settings/personal-access-tokens/new")!)
                .font(.caption.weight(.medium))
            Text("Välj endast repositoryn devh och ge Actions behörigheten Read and write. Token lämnar aldrig appen annat än i anropet till GitHub.")
                .font(.caption)
                .foregroundStyle(StudioTheme.secondaryText)
                .lineSpacing(3)
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(StudioTheme.surface, in: RoundedRectangle(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(StudioTheme.border, lineWidth: 1))
    }

    private var requestCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nytt uppdrag").font(.headline).foregroundStyle(StudioTheme.text)
            Picker("Projekt", selection: $selectedRepository) {
                ForEach(repositories, id: \.fullName) { item in
                    Text(item.name).tag(item.fullName)
                }
            }
            .pickerStyle(.menu)
            .tint(StudioTheme.accent)
            TextField("Vad vill du att AI:n ska undersöka?", text: $task, axis: .vertical)
                .lineLimit(4...7)
                .padding(12)
                .background(StudioTheme.elevated, in: RoundedRectangle(cornerRadius: 10))
            Button(action: submitTask) {
                HStack {
                    if isSending {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "paperplane.fill")
                    }
                    Text(isSending ? "Startar analys…" : "Skicka till AI-assistenten")
                }
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(StudioTheme.accent, in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.white)
            }
            .disabled(isSending || task.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !hasSavedToken)
            if !hasSavedToken {
                Text("Spara GitHub-token först för att aktivera assistenten.")
                    .font(.caption)
                    .foregroundStyle(StudioTheme.muted)
            }
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(StudioTheme.surface, in: RoundedRectangle(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(StudioTheme.border, lineWidth: 1))
    }

    private func statusCard(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle").foregroundStyle(StudioTheme.accent)
            Text(message).font(.subheadline).foregroundStyle(StudioTheme.secondaryText)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(StudioTheme.elevated, in: RoundedRectangle(cornerRadius: 12))
    }

    private func submitTask() {
        guard let token = GitHubTokenStore.read() else {
            statusMessage = "GitHub-token saknas. Spara den först."
            return
        }
        isSending = true
        statusMessage = nil
        workflowURL = nil
        let repository = selectedRepository
        let prompt = task.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            do {
                try await GitHubWorkflowClient.dispatch(repository: repository, task: prompt, token: token)
                await MainActor.run {
                    isSending = false
                    statusMessage = "Uppdraget har skickats till GitHub Actions. Öppna körningen för att följa analysen och läsa resultatet under Summary."
                    workflowURL = URL(string: "https://github.com/72cbbw422f-alt/devh/actions/workflows/ai-assistant.yml")
                    task = ""
                }
            } catch {
                await MainActor.run {
                    isSending = false
                    statusMessage = error.localizedDescription
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
        let attributes: [String: Any] = [kSecValueData as String: data]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
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
    static func dispatch(repository: String, task: String, token: String) async throws {
        guard let url = URL(string: "https://api.github.com/repos/72cbbw422f-alt/devh/actions/workflows/ai-assistant.yml/dispatches") else {
            throw WorkflowError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2026-03-10", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "ref": "main",
            "inputs": [
                "project_repository": repository,
                "task": task
            ]
        ])
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw WorkflowError.invalidResponse }
        guard (200...299).contains(http.statusCode) else {
            if http.statusCode == 401 || http.statusCode == 403 {
                throw WorkflowError.permission
            }
            throw WorkflowError.http(http.statusCode)
        }
    }

    private enum WorkflowError: LocalizedError {
        case invalidURL, invalidResponse, permission, http(Int)
        var errorDescription: String? {
            switch self {
            case .invalidURL: return "GitHub-adressen kunde inte skapas."
            case .invalidResponse: return "GitHub returnerade ett ogiltigt svar."
            case .permission: return "GitHub nekade åtkomst. Kontrollera att token gäller för devh och har Actions: Read and write."
            case .http(let code): return "GitHub-anropet misslyckades (HTTP \(code)). Kontrollera token och att workflow-filen finns på main."
            }
        }
    }
}
