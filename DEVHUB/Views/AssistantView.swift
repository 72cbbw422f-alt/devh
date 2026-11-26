import SwiftUI
import SwiftData
import Security
import ZIPFoundation

private struct AssistantRepository: Identifiable {
    let name: String
    let fullName: String
    var id: String { fullName }
}

struct AssistantView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ByteWorkItem.createdAt, order: .reverse) private var byteWorkItems: [ByteWorkItem]
    @State private var selectedRepository = "72cbbw422f-alt/project-orbit"
    @State private var task = ""
    @State private var queueFilter = "Alla"
    @State private var isRefreshingQueue = false
    @State private var githubToken = ""
    @State private var hasSavedToken = false
    @State private var isSending = false
    @State private var statusMessage: String?
    @State private var workflowURL: URL?
    @State private var runStatus: String?
    @State private var analysisText: String?
    @AppStorage("byte.workMode") private var workMode = "approval"
    @AppStorage("byte.allowAutomaticBuilds") private var allowAutomaticBuilds = true
    @AppStorage("byte.allowAutomaticPullRequests") private var allowAutomaticPullRequests = false
    @AppStorage("byte.alwaysConfirmDestructive") private var alwaysConfirmDestructive = true
    @AppStorage("byte.monthlyBudget") private var monthlyBudget = 200.0
    @FocusState private var focusedField: AssistantInput?

    private enum AssistantInput: Hashable { case token, task }

    private let repositories: [AssistantRepository] = [
        .init(name: "Regnvakt", fullName: "72cbbw422f-alt/project-orbit"),
        .init(name: "Familjen", fullName: "72cbbw422f-alt/fam"),
        .init(name: "Watchlist", fullName: "72cbbw422f-alt/watch"),
        .init(name: "Antikspanaren", fullName: "72cbbw422f-alt/vill"),
        .init(name: "Hemma", fullName: "72cbbw422f-alt/hem"),
        .init(name: "DEVHUB", fullName: "72cbbw422f-alt/devh")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("BYTE · DEVHUB AI", systemImage: "sparkles")
                        .font(.caption.bold()).foregroundStyle(StudioTheme.accent)
                    Text("Byte är redo att jobba")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(StudioTheme.text)
                    Text("Välj ett projekt och ge Byte ett uppdrag.")
                        .font(.subheadline).foregroundStyle(StudioTheme.secondaryText)
                }
                byteControlCard
                connectionCard
                requestCard
                byteQueueCard
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
                        Label("Bytes analys", systemImage: "sparkles")
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
                refreshQueueStatuses()
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 60_000_000_000)
                guard !Task.isCancelled else { break }
                refreshQueueStatuses()
            }
        }
    }

    private var byteControlCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "cpu.fill").font(.title3).foregroundStyle(StudioTheme.accent)
                    .frame(width: 38, height: 38).background(StudioTheme.elevated, in: RoundedRectangle(cornerRadius: 11))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Byte · Arbetsinställningar").font(.headline).foregroundStyle(StudioTheme.text)
                    Text("Välj hur självständigt Byte ska arbeta.").font(.caption).foregroundStyle(StudioTheme.muted)
                }
            }
            Picker("Arbetsläge", selection: $workMode) {
                Text("Fråga först").tag("approval")
                Text("Autopilot").tag("autopilot")
            }.pickerStyle(.segmented)
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: workMode == "autopilot" ? "sparkles" : "hand.raised.fill").foregroundStyle(StudioTheme.accent)
                Text(workMode == "autopilot" ? "Autopilot är valt. Automatiskt genomförande kopplas in i ett senare steg." : "Byte analyserar och föreslår. Du godkänner innan ändringar genomförs.")
                    .font(.caption).foregroundStyle(StudioTheme.secondaryText)
            }.frame(maxWidth: .infinity, alignment: .leading).padding(11).background(StudioTheme.elevated, in: RoundedRectangle(cornerRadius: 10))
            Toggle("Starta byggningar automatiskt", isOn: $allowAutomaticBuilds).tint(StudioTheme.accent)
            Toggle("Tillåt automatiska pull requests", isOn: $allowAutomaticPullRequests).tint(StudioTheme.accent)
            Toggle("Kräv alltid godkännande för radering och överskrivning", isOn: $alwaysConfirmDestructive).tint(StudioTheme.accent)
            Divider().overlay(StudioTheme.border)
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Månadsbudget för AI").font(.subheadline.weight(.semibold)).foregroundStyle(StudioTheme.text)
                    Text("Budgettak i kronor · lokal inställning").font(.caption).foregroundStyle(StudioTheme.muted)
                }
                Spacer()
                TextField("200", value: $monthlyBudget, format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 82)
                    .padding(9).background(StudioTheme.elevated, in: RoundedRectangle(cornerRadius: 9)).foregroundStyle(StudioTheme.text)
                Text("kr").font(.caption.weight(.semibold)).foregroundStyle(StudioTheme.secondaryText)
            }
        }.padding(15).frame(maxWidth: .infinity, alignment: .leading)
            .background(StudioTheme.surface, in: RoundedRectangle(cornerRadius: 15))
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(StudioTheme.border, lineWidth: 1))
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
                Text("Spara GitHub-token först för att aktivera Byte.")
                    .font(.caption).foregroundStyle(StudioTheme.muted)
            }
        }
        .padding(15).frame(maxWidth: .infinity, alignment: .leading)
        .background(StudioTheme.surface, in: RoundedRectangle(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(StudioTheme.border, lineWidth: 1))
    }

    private var byteQueueCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Bytes arbetskö", systemImage: "tray.full.fill")
                    .font(.headline).foregroundStyle(StudioTheme.text)
                Spacer()
                Text("\(filteredQueueItems.count) av \(byteWorkItems.count) uppdrag")
                    .font(.caption.monospacedDigit()).foregroundStyle(StudioTheme.muted)
                Button {
                    refreshQueueStatuses()
                } label: {
                    if isRefreshingQueue {
                        ProgressView().tint(StudioTheme.accent)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .disabled(isRefreshingQueue || !byteWorkItems.contains(where: {
                    $0.workflowRunID != nil && ($0.statusRawValue == "running" || ($0.statusRawValue == "completed" && $0.analysisText == nil))
                }))
                .accessibilityLabel("Uppdatera arbetskön")
            }
            Picker("Visa", selection: $queueFilter) {
                Text("Alla").tag("Alla")
                Text("Aktiva").tag("Aktiva")
                Text("Klara").tag("Klara")
                Text("Misslyckade").tag("Misslyckade")
            }
            .pickerStyle(.segmented)
            if filteredQueueItems.isEmpty {
                Text("Inga uppdrag i den här vyn ännu.")
                    .font(.caption).foregroundStyle(StudioTheme.muted)
            } else {
                ForEach(filteredQueueItems.prefix(12)) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: queueSymbol(item.statusRawValue))
                            .foregroundStyle(queueColor(item.statusRawValue))
                            .frame(width: 18)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(StudioTheme.text)
                                .lineLimit(3)
                            Text(item.projectRepository.replacingOccurrences(of: "72cbbw422f-alt/", with: "") + " · " + item.statusLabel)
                                .font(.caption).foregroundStyle(StudioTheme.muted)
                            Text(item.createdAt, style: .relative)
                                .font(.caption2).foregroundStyle(StudioTheme.muted)
                            if let analysis = item.analysisText, !analysis.isEmpty {
                                Text(analysis)
                                    .font(.caption)
                                    .foregroundStyle(StudioTheme.secondaryText)
                                    .lineLimit(3)
                                    .textSelection(.enabled)
                                DisclosureGroup("Läs hela analysen") {
                                    Group {
                                        if let formatted = try? AttributedString(markdown: analysis) {
                                            Text(formatted)
                                        } else {
                                            Text(analysis)
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundStyle(StudioTheme.secondaryText)
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.top, 6)
                                }
                                .font(.caption.weight(.semibold))
                                .tint(StudioTheme.accentCyan)
                            } else if item.statusRawValue == "completed" {
                                Text("Analysen är klar. Resultatet hämtas…")
                                    .font(.caption)
                                    .foregroundStyle(StudioTheme.muted)
                            }
                            if let rawURL = item.workflowURL, let url = URL(string: rawURL) {
                                Link("Öppna körning", destination: url)
                                    .font(.caption.weight(.semibold)).tint(StudioTheme.accentCyan)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(10)
                    .background(StudioTheme.elevated, in: RoundedRectangle(cornerRadius: 10))
                }
            }
            Text("Kön är lokal på den här enheten och synkroniseras ännu inte mellan användare eller appar.")
                .font(.caption2).foregroundStyle(StudioTheme.muted)
        }
        .padding(15).frame(maxWidth: .infinity, alignment: .leading)
        .background(StudioTheme.surface, in: RoundedRectangle(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(StudioTheme.border, lineWidth: 1))
    }

    private func refreshQueueStatuses() {
        guard let token = GitHubTokenStore.read() else {
            statusMessage = "GitHub-token saknas. Spara den först för att uppdatera arbetskön."
            return
        }
        let pendingItems = byteWorkItems.filter {
            $0.workflowRunID != nil && ($0.statusRawValue == "running" || ($0.statusRawValue == "completed" && $0.analysisText == nil))
        }
        guard !pendingItems.isEmpty else { return }
        isRefreshingQueue = true
        Task {
            var completedCount = 0
            var failedCount = 0
            var recoveredCount = 0
            var errorCount = 0
            for item in pendingItems {
                guard let runID = item.workflowRunID else { continue }
                do {
                    let status = try await GitHubWorkflowClient.fetchRunStatus(runID: runID, token: token)
                    var shouldFetchAnalysis = false
                    await MainActor.run {
                        item.workflowURL = status.url?.absoluteString ?? item.workflowURL
                        item.updatedAt = .now
                        if status.status == "completed" {
                            if status.conclusion == "success" {
                                if item.statusRawValue != "completed" { completedCount += 1 }
                                item.statusRawValue = "completed"
                                shouldFetchAnalysis = item.analysisText == nil
                            } else {
                                if item.statusRawValue != "failed" { failedCount += 1 }
                                item.statusRawValue = "failed"
                                modelContext.insert(DEVHUBNotification(
                                    title: "Byte-körningen misslyckades",
                                    message: "GitHub avslutade uppdraget med status: \(status.conclusion ?? "okänt fel").",
                                    category: "issue",
                                    destinationURL: status.url?.absoluteString
                                ))
                            }
                        }
                    }
                    if shouldFetchAnalysis {
                        let analysis = try await GitHubWorkflowClient.fetchAnalysis(runID: runID, token: token)
                        await MainActor.run {
                            item.analysisText = analysis
                            recoveredCount += 1
                            modelContext.insert(DEVHUBNotification(
                                title: "Byte har levererat analysen",
                                message: "Resultatet för uppdraget ‘\(item.title)’ har hämtats till arbetskön.",
                                category: "assistant",
                                destinationURL: item.workflowURL
                            ))
                        }
                    }
                } catch {
                    errorCount += 1
                }
            }
            await MainActor.run {
                isRefreshingQueue = false
                statusMessage = "Arbetskön uppdaterad: \\(completedCount) nya klara, \\(recoveredCount) analyser återhämtade, \\(failedCount) misslyckade, \\(errorCount) kunde inte kontrolleras."
            }
        }
    }

    private var filteredQueueItems: [ByteWorkItem] {
        switch queueFilter {
        case "Aktiva": byteWorkItems.filter { $0.statusRawValue == "queued" || $0.statusRawValue == "running" }
        case "Klara": byteWorkItems.filter { $0.statusRawValue == "completed" }
        case "Misslyckade": byteWorkItems.filter { $0.statusRawValue == "failed" }
        default: byteWorkItems
        }
    }

    private func queueSymbol(_ status: String) -> String {
        switch status {
        case "running": "arrow.triangle.2.circlepath"
        case "completed": "checkmark.circle.fill"
        case "failed": "exclamationmark.circle.fill"
        default: "clock"
        }
    }

    private func queueColor(_ status: String) -> Color {
        switch status {
        case "running": StudioTheme.accent
        case "completed": StudioTheme.accentCyan
        case "failed": .red
        default: StudioTheme.muted
        }
    }

    private func submitTask() {
        guard let token = GitHubTokenStore.read() else {
            statusMessage = "GitHub-token saknas. Spara den först."
            return
        }
        let prompt = task.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }
        focusedField = nil
        let queueItem = ByteWorkItem(projectRepository: selectedRepository, title: prompt)
        modelContext.insert(queueItem)
        let queueItemID = queueItem.id
        isSending = true
        statusMessage = nil
        workflowURL = nil
        analysisText = nil
        runStatus = "Skickar uppdraget till GitHub…"
        let startedAt = Date()
        Task {
            do {
                try await GitHubWorkflowClient.dispatch(repository: selectedRepository, task: prompt, token: token)
                await MainActor.run {
                    if let item = byteWorkItems.first(where: { $0.id == queueItemID }) {
                        item.statusRawValue = "running"
                        item.updatedAt = .now
                    }
                    statusMessage = "Uppdraget är mottaget. Väntar på AI-analysen…"
                    task = ""
                }
                let result = try await GitHubWorkflowClient.waitForRun(startedAt: startedAt, token: token) { runID, runURL in
                    await MainActor.run {
                        if let item = byteWorkItems.first(where: { $0.id == queueItemID }) {
                            item.workflowRunID = runID
                            item.workflowURL = runURL?.absoluteString
                            item.statusRawValue = "running"
                            item.updatedAt = .now
                        }
                    }
                }
                await MainActor.run {
                    isSending = false
                    if let item = byteWorkItems.first(where: { $0.id == queueItemID }) {
                        item.statusRawValue = result.message.contains("lyckades") ? "completed" : "failed"
                        item.updatedAt = .now
                        item.workflowURL = result.url?.absoluteString
                        item.workflowRunID = result.id
                    }
                    runStatus = result.message
                    workflowURL = result.url
                    modelContext.insert(DEVHUBNotification(
                        title: result.message.contains("lyckades") ? "Byte har slutfört en analys" : "Byte-körningen misslyckades",
                        message: result.message,
                        category: result.message.contains("lyckades") ? "assistant" : "issue",
                        destinationURL: result.url?.absoluteString
                    ))
                }
                if result.message.contains("lyckades") {
                    do {
                        let text = try await GitHubWorkflowClient.fetchAnalysis(runID: result.id, token: token)
                        await MainActor.run {
                            analysisText = text
                            if let item = byteWorkItems.first(where: { $0.id == queueItemID }) {
                                item.analysisText = text
                                item.updatedAt = .now
                            }
                            statusMessage = nil
                        }
                    } catch {
                        await MainActor.run { statusMessage = error.localizedDescription }
                    }
                }
            } catch GitHubWorkflowClient.WorkflowError.timeout {
                await MainActor.run {
                    isSending = false
                    if let item = byteWorkItems.first(where: { $0.id == queueItemID }) {
                        item.statusRawValue = "running"
                        item.updatedAt = .now
                    }
                    statusMessage = "Byte arbetar fortfarande i GitHub. Uppdraget ligger kvar som pågående – kontrollera Actions innan du skickar det igen."
                    runStatus = "Väntetiden i appen tog slut, men det betyder inte att GitHub-körningen har misslyckats."
                    modelContext.insert(DEVHUBNotification(
                        title: "Byte arbetar fortfarande",
                        message: "Appen slutade vänta, men GitHub-körningen kan fortfarande pågå.",
                        category: "assistant"
                    ))
                }
            } catch {
                await MainActor.run {
                    isSending = false
                    if let item = byteWorkItems.first(where: { $0.id == queueItemID }) {
                        item.statusRawValue = "failed"
                        item.updatedAt = .now
                    }
                    statusMessage = error.localizedDescription
                    runStatus = "Kunde inte bekräfta att AI-körningen blev klar."
                    modelContext.insert(DEVHUBNotification(
                        title: "Byte kunde inte slutföra uppdraget",
                        message: error.localizedDescription,
                        category: "issue"
                    ))
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

    struct RunStatus { let status: String; let conclusion: String?; let url: URL? }

    static func fetchRunStatus(runID: Int, token: String) async throws -> RunStatus {
        let endpoint = URL(string: "https://api.github.com/repos/72cbbw422f-alt/devh/actions/runs/\(runID)")!
        var request = URLRequest(url: endpoint)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw WorkflowError.statusCheck
        }
        let run = try JSONDecoder().decode(WorkflowRun.self, from: data)
        return RunStatus(status: run.status, conclusion: run.conclusion, url: URL(string: run.html_url))
    }

    static func waitForRun(
        startedAt: Date,
        token: String,
        onRunFound: @escaping (Int, URL?) async -> Void
    ) async throws -> RunResult {
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
            let runURL = URL(string: run.html_url)
            await onRunFound(run.id, runURL)
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

    enum WorkflowError: LocalizedError {
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
