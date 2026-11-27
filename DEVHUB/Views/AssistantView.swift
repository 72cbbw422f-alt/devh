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
    @Query(sort: \ByteWorkItem.updatedAt, order: .reverse) private var byteWorkItems: [ByteWorkItem]
    @Query private var projectTasks: [ProjectTaskItem]
    @Query private var projectMilestones: [ProjectMilestoneItem]
    @State private var selectedRepository = "72cbbw422f-alt/project-orbit"
    @State private var analysisRepository = "72cbbw422f-alt/project-orbit"
    @State private var task = ""
    @State private var queueFilter = "Alla"
    @State private var queueSearch = ""
    @State private var queueProjectFilter = "Alla projekt"
    @State private var showsAllQueueItems = false
    @State private var isRefreshingQueue = false
    @State private var refreshingPatchItemIDs: Set<String> = []
    @State private var githubToken = ""
    @State private var hasSavedToken = false
    @State private var isSending = false
    @State private var statusMessage: String?
    @State private var workflowURL: URL?
    @State private var runStatus: String?
    @State private var analysisText: String?
    @State private var analysisTaskProposalJSON: String?
    @State private var continuingFromResponseID: String?
    @AppStorage("byte.workMode") private var workMode = "approval"
    @AppStorage("byte.allowAutomaticBuilds") private var allowAutomaticBuilds = true
    @AppStorage("byte.allowAutomaticPullRequests") private var allowAutomaticPullRequests = false
    @AppStorage("byte.alwaysConfirmDestructive") private var alwaysConfirmDestructive = true
    @AppStorage("byte.monthlyBudget") private var monthlyBudget = 200.0
    @FocusState private var focusedField: AssistantInput?

    private enum AssistantInput: Hashable { case token, task, budget }

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
                    HStack(spacing: 12) {
                        Image("ByteMascot")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 58, height: 58)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .accessibilityLabel("Byte, DEVHUBs AI-maskot")
                        VStack(alignment: .leading, spacing: 5) {
                            Text("BYTE · DEVHUB AI")
                                .font(.caption.bold())
                                .foregroundStyle(StudioTheme.accent)
                            Text("Byte är redo att jobba")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(StudioTheme.text)
                        }
                    }
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
                        if let proposalJSON = analysisTaskProposalJSON {
                            Button {
                                importByteTaskProposals(json: proposalJSON)
                            } label: {
                                Label("Lägg Bytes uppgifter i arbetslistan", systemImage: "checklist")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(12)
                                    .background(StudioTheme.elevated, in: RoundedRectangle(cornerRadius: 10))
                            }
                            .tint(StudioTheme.accentCyan)
                        }
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
                Text("Byte analyserar projektet utan att ändra kod. Kodförslag visas som diff och kan skickas till GitHub först efter ditt uttryckliga godkännande. GitHub kontrollerar sedan grundversionen och öppnar en separat pull request för granskning.")
                    .font(.caption).foregroundStyle(StudioTheme.muted)
            }
            .padding(28).frame(maxWidth: 1080).frame(maxWidth: .infinity, alignment: .topLeading)
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
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if let token = GitHubTokenStore.read() {
                githubToken = token
                hasSavedToken = true
                refreshQueueStatuses()
                refreshPendingApprovedPatchStatuses()
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 60_000_000_000)
                guard !Task.isCancelled else { break }
                refreshQueueStatuses()
                refreshPendingApprovedPatchStatuses()
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
                Text("Snabbt svar").tag("quick")
                Text("Samarbeta").tag("collaborate")
                Text("Godkänn först").tag("approval")
                Text("Autopilot").tag("autopilot")
            }.pickerStyle(.menu)
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: workMode == "quick" ? "bolt.fill" : (workMode == "autopilot" ? "sparkles" : (workMode == "collaborate" ? "messages" : "hand.raised.fill")))
                    .foregroundStyle(StudioTheme.accent)
                Text(workModeDescription)
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
                    .focused($focusedField, equals: .budget)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 82)
                    .padding(9)
                    .background(StudioTheme.elevated, in: RoundedRectangle(cornerRadius: 9))
                    .foregroundStyle(StudioTheme.text)
                    .accessibilityLabel("Månadsbudget för AI i kronor")
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
            Text("App-token: endast devh med Actions: Read and write. Skrivtokenen PROJECTS_GITHUB_TOKEN ligger separat som GitHub Secret och ska bara ha skrivåtkomst till projektens Contents och Pull requests.")
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
            if let continuingFromResponseID {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.turn.down.right")
                        .foregroundStyle(StudioTheme.accentCyan)
                    Text(workMode == "collaborate" ? "Fortsätter ett befintligt Byte-samtal" : "Välj Samarbeta för att behålla samtalets sammanhang")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(StudioTheme.accentCyan)
                    Spacer()
                    Button("Avsluta") { self.continuingFromResponseID = nil }
                        .font(.caption)
                }
                .padding(10)
                .background(StudioTheme.elevated, in: RoundedRectangle(cornerRadius: 9))
            }
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
                    refreshPendingApprovedPatchStatuses()
                } label: {
                    if isRefreshingQueue {
                        ProgressView().tint(StudioTheme.accent)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .disabled(isRefreshingQueue || (
                    !byteWorkItems.contains(where: {
                        guard let runID = $0.workflowRunID else { return false }
                        return $0.statusRawValue == "running" ||
                            ($0.statusRawValue == "completed" && $0.analysisText == nil) ||
                            ($0.statusRawValue == "failed" && $0.workflowFailureDetails == nil)
                    }) &&
                    !byteWorkItems.contains(where: { $0.patchStatusRawValue == "dispatched" || $0.patchStatusRawValue == "running" })
                ))
                .accessibilityLabel("Uppdatera arbetskön")
            }
            let pendingPatchCount = byteWorkItems.filter { $0.patchStatusRawValue == "dispatched" || $0.patchStatusRawValue == "running" }.count
            if pendingPatchCount > 0 {
                Label("Automatisk GitHub-kontroll aktiv · \\(pendingPatchCount) väntande förslag · var 60:e sekund", systemImage: "arrow.triangle.2.circlepath")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(StudioTheme.accentCyan)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Label("Automatisk GitHub-kontroll aktiv · var 60:e sekund", systemImage: "checkmark.icloud")
                    .font(.caption2)
                    .foregroundStyle(StudioTheme.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            TextField("Sök uppdrag eller analys", text: $queueSearch)
                .textFieldStyle(.plain)
                .padding(11)
                .background(StudioTheme.elevated, in: RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(StudioTheme.text)
            Picker("Projekt", selection: $queueProjectFilter) {
                Text("Alla projekt").tag("Alla projekt")
                ForEach(Array(Set(byteWorkItems.map(\.projectRepository))).sorted(), id: \.self) { repository in
                    Text(repository.replacingOccurrences(of: "72cbbw422f-alt/", with: "")).tag(repository)
                }
            }
            .pickerStyle(.menu).tint(StudioTheme.accent)
            HStack(spacing: 8) {
                queueMetric(title: "Aktiva", count: byteWorkItems.filter { $0.statusRawValue == "queued" || $0.statusRawValue == "running" }.count, color: StudioTheme.accent)
                queueMetric(title: "PR väntar", count: byteWorkItems.filter { $0.patchStatusRawValue == "dispatched" || $0.patchStatusRawValue == "running" }.count, color: .orange)
                queueMetric(title: "Klara", count: byteWorkItems.filter { $0.statusRawValue == "completed" || $0.patchStatusRawValue == "completed" }.count, color: StudioTheme.accentCyan)
                queueMetric(title: "Fel", count: byteWorkItems.filter { $0.statusRawValue == "failed" || $0.patchStatusRawValue == "failed" }.count, color: .red)
            }
            Picker("Visa", selection: $queueFilter) {
                Text("Alla").tag("Alla")
                Text("Aktiva").tag("Aktiva")
                Text("PR väntar").tag("PR väntar")
                Text("Klara").tag("Klara")
                Text("Misslyckade").tag("Misslyckade")
            }
            .pickerStyle(.segmented)
            if filteredQueueItems.isEmpty {
                Text("Inga uppdrag i den här vyn ännu.")
                    .font(.caption).foregroundStyle(StudioTheme.muted)
            } else {
                ForEach(showsAllQueueItems ? filteredQueueItems : Array(filteredQueueItems.prefix(12))) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: queueSymbol(item.statusRawValue))
                            .foregroundStyle(queueColor(item.statusRawValue))
                            .frame(width: 18)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(StudioTheme.text)
                                .lineLimit(3)
                            Text(item.projectRepository.replacingOccurrences(of: "72cbbw422f-alt/", with: "") + " · " + item.workModeLabel + " · " + item.statusLabel)
                                .font(.caption).foregroundStyle(StudioTheme.muted)
                            if item.patchStatusRawValue != "pending" {
                                Label(patchQueueStatusLabel(item.patchStatusRawValue), systemImage: patchQueueStatusSymbol(item.patchStatusRawValue))
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(patchQueueStatusColor(item.patchStatusRawValue))
                            }
                            Text("Senast ändrad ") + Text(item.updatedAt, style: .relative)
                                .font(.caption2).foregroundStyle(StudioTheme.muted)
                            if item.inputTokens > 0 || item.outputTokens > 0 {
                                Text("\(item.inputTokens.formatted()) in · \(item.outputTokens.formatted()) ut · $\(item.costUSD, format: .number.precision(.fractionLength(5)))")
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(StudioTheme.accentCyan)
                            }
                            if let savedAnalysis = item.analysisText, !savedAnalysis.isEmpty {
                                Button {
                                    analysisText = savedAnalysis
                                    analysisTaskProposalJSON = item.taskProposalJSON
                                    analysisRepository = item.projectRepository
                                    selectedRepository = item.projectRepository
                                    statusMessage = "Visar sparad analys: " + item.title
                                } label: {
                                    Label("Visa sparad analys", systemImage: "doc.text.magnifyingglass")
                                        .font(.caption.weight(.semibold))
                                }
                                .tint(StudioTheme.accentCyan)
                            }
                            if let patchPreview = item.patchPreview, !patchPreview.isEmpty {
                                DisclosureGroup {
                                    ScrollView(.horizontal) {
                                        Text(patchPreview)
                                            .font(.system(.caption2, design: .monospaced))
                                            .foregroundStyle(StudioTheme.secondaryText)
                                            .textSelection(.enabled)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(9)
                                    }
                                    .background(StudioTheme.background, in: RoundedRectangle(cornerRadius: 8))
                                } label: {
                                    Label("Granska kodförslag", systemImage: "doc.text.magnifyingglass")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(StudioTheme.accentCyan)
                                }
                                Text("Förhandsvisning – ingen kod har ändrats eller godkänts för incheckning.")
                                    .font(.caption2)
                                    .foregroundStyle(StudioTheme.muted)
                                if let patchPreview = item.patchPreview, !patchPreview.isEmpty {
                                    HStack(spacing: 12) {
                                        switch item.patchStatusRawValue {
                                        case "dispatched":
                                            Label("Begäran mottagen · väntar på GitHub", systemImage: "clock")
                                                .font(.caption.weight(.semibold)).foregroundStyle(.orange)
                                        case "running":
                                            Label("GitHub arbetar med förslaget…", systemImage: "arrow.triangle.2.circlepath")
                                                .font(.caption.weight(.semibold)).foregroundStyle(StudioTheme.accentCyan)
                                        case "completed":
                                            Label("PR skapad · redo för granskning", systemImage: "checkmark.circle.fill")
                                                .font(.caption.weight(.semibold)).foregroundStyle(.green)
                                        case "failed":
                                            Label("GitHub kunde inte skapa PR", systemImage: "exclamationmark.circle.fill")
                                                .font(.caption.weight(.semibold)).foregroundStyle(.red)
                                        default:
                                            Button { approvePatch(for: item) } label: {
                                                Label("Godkänn och skapa PR", systemImage: "checkmark.shield")
                                                    .font(.caption.weight(.semibold))
                                            }
                                            .tint(StudioTheme.accent)
                                            .disabled(item.patchStatusRawValue == "dispatching" || item.baseCommitSHA == nil || !patchPreview.contains("--- ") || !patchPreview.contains("+++ "))
                                            if item.patchStatusRawValue == "dispatching" { ProgressView().controlSize(.small) }
                                        }
                                        if item.patchStatusRawValue == "dispatched" || item.patchStatusRawValue == "running" {
                                            Button { refreshApprovedPatchStatus(for: item) } label: {
                                                Label("Kontrollera status", systemImage: "arrow.clockwise")
                                                    .font(.caption.weight(.semibold))
                                            }
                                            .tint(StudioTheme.accent)
                                        }
                                        if let rawURL = item.patchPullRequestURL, let url = URL(string: rawURL) {
                                            Link(destination: url) {
                                                Label("Öppna pull request", systemImage: "arrow.up.right.square")
                                                    .font(.caption.weight(.semibold))
                                            }
                                            .tint(StudioTheme.accentCyan)
                                        }
                                        if let rawURL = item.patchWorkflowURL, let url = URL(string: rawURL) {
                                            Link("Följ GitHub-jobbet", destination: url)
                                                .font(.caption.weight(.semibold)).tint(StudioTheme.accentCyan)
                                        }
                                        if let details = item.patchFailureDetails {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Label("Felorsak", systemImage: "exclamationmark.triangle.fill")
                                                    .font(.caption.weight(.semibold)).foregroundStyle(.red)
                                                Text(details).font(.caption2).foregroundStyle(StudioTheme.secondaryText)
                                                    .textSelection(.enabled)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        if item.patchStatusRawValue == "failed", item.patchFailureDetails == nil,
                                           let runID = item.patchWorkflowRunID {
                                            Button {
                                                refreshPatchFailureDetails(for: item, runID: runID)
                                            } label: {
                                                Label("Hämta felorsak från GitHub", systemImage: "arrow.clockwise")
                                                    .font(.caption.weight(.semibold))
                                            }
                                            .tint(StudioTheme.accentCyan)
                                        }
                                    }
                                    if item.baseCommitSHA == nil {
                                        Text("Kan inte godkännas ännu: grundversionen saknas. Uppdatera analysen.")
                                            .font(.caption2).foregroundStyle(.orange)
                                    }
                                }
                            }
                            if item.statusRawValue == "failed", let runID = item.workflowRunID {
                                if let details = item.workflowFailureDetails {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Label("Felorsak", systemImage: "exclamationmark.triangle.fill")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.red)
                                        Text(details)
                                            .font(.caption2)
                                            .foregroundStyle(StudioTheme.secondaryText)
                                            .textSelection(.enabled)
                                    }
                                    .padding(9)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(StudioTheme.background, in: RoundedRectangle(cornerRadius: 8))
                                } else {
                                    Text("Felorsak kan hämtas från GitHub. Tryck på uppdatera-knappen ovan.")
                                        .font(.caption2)
                                        .foregroundStyle(StudioTheme.muted)
                                }
                            }
                            if let analysis = item.analysisText, !analysis.isEmpty {
                                Group {
                                    if let formatted = try? AttributedString(markdown: analysis) {
                                        Text(formatted)
                                    } else {
                                        Text(analysis)
                                    }
                                }
                                .font(.caption)
                                .foregroundStyle(StudioTheme.secondaryText)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineLimit(5)
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
                                if let proposalJSON = item.taskProposalJSON {
                                    Button {
                                        importByteTaskProposals(json: proposalJSON, repository: item.projectRepository)
                                    } label: {
                                        Label("Importera Bytes uppgifter", systemImage: "checklist")
                                            .font(.caption.weight(.semibold))
                                    }
                                    .tint(StudioTheme.accentCyan)
                                }
                            } else if item.statusRawValue == "completed" {
                                Text("Analysen är klar. Resultatet hämtas…")
                                    .font(.caption)
                                    .foregroundStyle(StudioTheme.muted)
                            }
                            HStack(spacing: 14) {
                                if let responseID = item.conversationResponseID {
                                    Button {
                                        selectedRepository = item.projectRepository
                                        analysisRepository = item.projectRepository
                                        workMode = "collaborate"
                                        continuingFromResponseID = responseID
                                        task = ""
                                        focusedField = .task
                                        statusMessage = "Du fortsätter nu samtalet med Byte från det här uppdraget."
                                    } label: {
                                        Label("Återuppta Byte-samtal", systemImage: "bubble.left.and.bubble.right")
                                            .font(.caption.weight(.semibold))
                                    }
                                    .tint(StudioTheme.accent)
                                }
                                if let rawURL = item.workflowURL, let url = URL(string: rawURL) {
                                    Link("Öppna körning", destination: url)
                                        .font(.caption.weight(.semibold)).tint(StudioTheme.accentCyan)
                                }
                                if let analysis = item.analysisText, !analysis.isEmpty {
                                    ShareLink(item: analysis) {
                                        Label("Dela analys", systemImage: "square.and.arrow.up")
                                            .font(.caption.weight(.semibold))
                                    }
                                    .tint(StudioTheme.accentCyan)
                                }
                                Button {
                                    selectedRepository = item.projectRepository
                                    task = item.title
                                    focusedField = .task
                                    statusMessage = "Uppdraget har kopierats. Anpassa texten och skicka när du är redo."
                                } label: {
                                    Label("Återanvänd uppdrag", systemImage: "arrow.uturn.forward")
                                        .font(.caption.weight(.semibold))
                                }
                                .tint(StudioTheme.accent)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(10)
                    .background(StudioTheme.elevated, in: RoundedRectangle(cornerRadius: 10))
                }
                if filteredQueueItems.count > 12 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showsAllQueueItems.toggle()
                        }
                    } label: {
                        Label(
                            showsAllQueueItems ? "Visa färre uppdrag" : "Visa alla \(filteredQueueItems.count) uppdrag",
                            systemImage: showsAllQueueItems ? "chevron.up" : "chevron.down"
                        )
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(StudioTheme.accentCyan)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                }
            }
            Text("Välj PR väntar för att samla godkända förslag som fortfarande behandlas. Öppna en sparad analys direkt från historiken.")
                .font(.caption2).foregroundStyle(StudioTheme.muted)
            Text("Kön är lokal på den här enheten och synkroniseras ännu inte mellan användare eller appar.")
                .font(.caption2).foregroundStyle(StudioTheme.muted)
        }
        .padding(15).frame(maxWidth: .infinity, alignment: .leading)
        .background(StudioTheme.surface, in: RoundedRectangle(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(StudioTheme.border, lineWidth: 1))
    }

    private func refreshQueueStatuses() {
        guard !isRefreshingQueue else { return }
        guard let token = GitHubTokenStore.read() else {
            statusMessage = "GitHub-token saknas. Spara den först för att uppdatera arbetskön."
            return
        }
        let pendingItems = byteWorkItems.filter {
            guard let runID = $0.workflowRunID else { return false }
            return $0.statusRawValue == "running" ||
                ($0.statusRawValue == "completed" && $0.analysisText == nil) ||
                ($0.statusRawValue == "failed" && $0.workflowFailureDetails == nil)
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
                    if status.status == "completed", status.conclusion != "success" {
                        let details = try await GitHubWorkflowClient.fetchFailureSummary(runID: runID, token: token)
                        await MainActor.run { item.workflowFailureDetails = details }
                    }
                    if shouldFetchAnalysis {
                        let analysis = try await GitHubWorkflowClient.fetchAnalysis(runID: runID, token: token)
                        await MainActor.run {
                            let responseID = extractResponseID(from: analysis)
                            applyUsage(from: analysis, to: item)
                            item.taskProposalJSON = extractTaskProposalJSON(from: analysis)
                            item.analysisText = cleanAnalysis(from: analysis, responseID: responseID)
                            item.patchPreview = extractPatchPreview(from: analysis)
                            item.baseCommitSHA = extractBaseSHA(from: analysis)
                            item.conversationResponseID = responseID ?? item.conversationResponseID
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
                statusMessage = "Arbetskön uppdaterad: \(completedCount) nya klara, \(recoveredCount) analyser återhämtade, \(failedCount) misslyckade, \(errorCount) kunde inte kontrolleras."
            }
        }
    }

    private func extractPatchPreview(from text: String) -> String? {
        let pattern = #"(?is)```(?:diff|patch)\s*\n(.*?)\n```"#
        guard let expression = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        let matches = expression.matches(in: text, range: range)
        let previews = matches.compactMap { match -> String? in
            guard match.numberOfRanges > 1,
                  let range = Range(match.range(at: 1), in: text) else { return nil }
            let value = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            return value.isEmpty ? nil : value
        }
        return previews.isEmpty ? nil : previews.joined(separator: "\n\n")
    }

    private func extractBaseSHA(from text: String) -> String? {
        guard let marker = text.range(of: "<!-- DEVHUB_BASE_SHA:"),
              let end = text[marker.upperBound...].range(of: " -->") else { return nil }
        let value = String(text[marker.upperBound..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard value.count == 40, value.allSatisfy({ $0.isHexDigit }) else { return nil }
        return value
    }

    private func extractResponseID(from text: String) -> String? {
        guard let marker = text.range(of: "<!-- DEVHUB_RESPONSE_ID:"),
              let end = text[marker.upperBound...].range(of: " -->") else { return nil }
        let value = String(text[marker.upperBound..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    private func applyUsage(from text: String, to item: ByteWorkItem) {
        guard let marker = text.range(of: "<!-- DEVHUB_USAGE:"),
              let end = text[marker.upperBound...].range(of: " -->") else { return }
        let json = String(text[marker.upperBound..<end.lowerBound])
        guard let data = json.data(using: .utf8),
              let usage = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        item.inputTokens = usage["input_tokens"] as? Int ?? item.inputTokens
        item.outputTokens = usage["output_tokens"] as? Int ?? item.outputTokens
        item.costUSD = usage["cost_usd"] as? Double ?? item.costUSD
    }

    private func extractTaskProposalJSON(from text: String) -> String? {
        guard let start = text.range(of: "<!-- DEVHUB_TASKS_BEGIN -->"),
              let end = text.range(of: "<!-- DEVHUB_TASKS_END -->"),
              start.upperBound <= end.lowerBound else { return nil }
        let value = String(text[start.upperBound..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = value.data(using: .utf8),
              (try? JSONSerialization.jsonObject(with: data)) is [[String: Any]] else { return nil }
        return value
    }

    private func cleanAnalysis(from text: String, responseID: String?) -> String {
        var cleaned = text
        let technicalMarkers = [
            "<!-- DEVHUB_TASKS_BEGIN -->",
            "<!-- DEVHUB_TASKS_END -->"
        ]
        if let start = cleaned.range(of: technicalMarkers[0]),
           let end = cleaned.range(of: technicalMarkers[1]),
           start.lowerBound <= end.upperBound {
            cleaned.removeSubrange(start.lowerBound..<end.upperBound)
        }
        if let baseSHA = extractBaseSHA(from: cleaned) {
            cleaned = cleaned.replacingOccurrences(of: "<!-- DEVHUB_BASE_SHA:\(baseSHA) -->", with: "")
        }
        if let responseID {
            cleaned = cleaned.replacingOccurrences(of: "<!-- DEVHUB_RESPONSE_ID:\(responseID) -->", with: "")
        }
        if let marker = cleaned.range(of: "<!-- DEVHUB_USAGE:"),
           let end = cleaned[marker.upperBound...].range(of: " -->") {
            cleaned.removeSubrange(marker.lowerBound..<end.upperBound)
        }
        let lines = cleaned.components(separatedBy: .newlines).filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            return trimmed != "# DEVHUB AI analysis"
                && !trimmed.hasPrefix("**Project:**")
                && !trimmed.hasPrefix("**Task:**")
                && !trimmed.hasPrefix("**Working mode:**")
        }
        return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var workModeDescription: String {
        switch workMode {
        case "quick":
            return "Snabbt svar: För enkla allmänna frågor. Byte hoppar över projektinläsning och ger ett kortare svar."
        case "collaborate":
            return "Samarbeta: Fortsätt samma konversation med Byte. Tidigare sammanhang följer med när du väljer Fortsätt samtal."
        case "autopilot":
            return "Autopilot: Byte analyserar uppdraget självständigt och föreslår nästa steg. Automatisk kodskrivning och PR-skapande är ännu inte aktiverat."
        default:
            return "Godkänn först: Byte analyserar projektet och kan visa konkreta unified-diff-förslag per fil. Förslagen är endast förhandsvisningar – inga filer ändras innan du uttryckligen godkänt dem."
        }
    }

    private func queueMetric(title: String, count: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(count.formatted())
                .font(.headline.monospacedDigit())
                .foregroundStyle(color)
            Text(title)
                .font(.caption2)
                .foregroundStyle(StudioTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(StudioTheme.elevated, in: RoundedRectangle(cornerRadius: 10))
    }

    private var filteredQueueItems: [ByteWorkItem] {
        byteWorkItems.filter { item in
            let matchesStatus: Bool
            switch queueFilter {
            case "Aktiva": matchesStatus = item.statusRawValue == "queued" || item.statusRawValue == "running"
            case "PR väntar":
                matchesStatus = item.patchStatusRawValue == "dispatching" || item.patchStatusRawValue == "dispatched" || item.patchStatusRawValue == "running"
            case "Klara":
                matchesStatus = item.statusRawValue == "completed" || item.patchStatusRawValue == "completed"
            case "Misslyckade":
                matchesStatus = item.statusRawValue == "failed" || item.patchStatusRawValue == "failed"
            default: matchesStatus = true
            }
            let matchesProject = queueProjectFilter == "Alla projekt" || item.projectRepository == queueProjectFilter
            let query = queueSearch.trimmingCharacters(in: .whitespacesAndNewlines)
            let matchesSearch = query.isEmpty
                || item.title.localizedCaseInsensitiveContains(query)
                || item.projectRepository.localizedCaseInsensitiveContains(query)
                || (item.analysisText?.localizedCaseInsensitiveContains(query) ?? false)
            return matchesStatus && matchesProject && matchesSearch
        }
    }

    private func patchQueueStatusLabel(_ status: String) -> String {
        switch status {
        case "dispatching": "Skickar godkännande"
        case "dispatched": "Väntar på GitHub"
        case "running": "GitHub skapar PR"
        case "completed": "PR klar för granskning"
        case "failed": "PR-skapandet misslyckades"
        default: "Kodförslag finns"
        }
    }

    private func patchQueueStatusSymbol(_ status: String) -> String {
        switch status {
        case "dispatching", "dispatched": "clock"
        case "running": "arrow.triangle.2.circlepath"
        case "completed": "checkmark.circle.fill"
        case "failed": "exclamationmark.circle.fill"
        default: "doc.text"
        }
    }

    private func patchQueueStatusColor(_ status: String) -> Color {
        switch status {
        case "dispatching", "dispatched": .orange
        case "running": StudioTheme.accentCyan
        case "completed": .green
        case "failed": .red
        default: StudioTheme.muted
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

    private func approvePatch(for item: ByteWorkItem) {
        guard let token = GitHubTokenStore.read() else { statusMessage = "GitHub-token saknas. Spara den först."; return }
        guard let baseSHA = item.baseCommitSHA, let patch = item.patchPreview,
              patch.contains("--- "), patch.contains("+++ ") else {
            statusMessage = "Kodförslaget saknar en giltig diff eller grundversion."; return
        }
        guard item.patchStatusRawValue != "dispatching" && item.patchStatusRawValue != "dispatched" else { return }
        item.patchStatusRawValue = "dispatching"
        item.patchWorkflowRunID = nil
        item.patchWorkflowURL = nil
        let startedAt = Date()
        item.patchDispatchedAt = startedAt
        item.patchFailureDetails = nil
        statusMessage = "Skickar ditt godkända förslag till GitHub…"
        Task {
            var dispatchAccepted = false
            do {
                try await GitHubWorkflowClient.dispatchApprovedPatch(repository: item.projectRepository, baseSHA: baseSHA, patch: patch, title: item.title, token: token)
                dispatchAccepted = true
                await MainActor.run {
                    item.patchStatusRawValue = "dispatched"
                    item.updatedAt = .now
                    statusMessage = "GitHub har tagit emot godkännandet. Väntar på att arbetsflödet startar…"
                }
                let result = try await GitHubWorkflowClient.waitForApprovedPatchRun(startedAt: startedAt, expectedTitle: String(item.title.prefix(120)), token: token) { runID, runURL in
                    await MainActor.run {
                        item.patchWorkflowRunID = runID
                        item.patchWorkflowURL = runURL?.absoluteString
                        item.patchStatusRawValue = "running"
                        item.updatedAt = .now
                    }
                }
                let succeeded = result.message.contains("lyckades")
                let failureDetails = succeeded ? nil : try? await GitHubWorkflowClient.fetchFailureSummary(runID: result.id, token: token)
                let pullRequestURL = succeeded
                    ? await GitHubWorkflowClient.fetchPullRequestURL(repository: item.projectRepository, runID: result.id, title: item.title, token: token)
                    : nil
                await MainActor.run {
                    item.patchStatusRawValue = succeeded ? "completed" : "failed"
                    item.patchFailureDetails = failureDetails
                    item.patchPullRequestURL = pullRequestURL?.absoluteString ?? item.patchPullRequestURL
                    item.updatedAt = .now
                    item.patchWorkflowURL = result.url?.absoluteString ?? item.patchWorkflowURL
                    statusMessage = result.message
                    modelContext.insert(DEVHUBNotification(
                        title: result.message.contains("lyckades") ? "Byte har skapat ett PR-förslag" : "Byte kunde inte skapa PR",
                        message: result.message,
                        category: result.message.contains("lyckades") ? "assistant" : "issue",
                        destinationURL: result.url?.absoluteString
                    ))
                }
            } catch GitHubWorkflowClient.WorkflowError.timeout {
                await MainActor.run {
                    item.patchStatusRawValue = item.patchWorkflowRunID == nil ? "dispatched" : "running"
                    item.updatedAt = .now
                    statusMessage = "GitHub tog emot godkännandet, men DEVHUB hann inte bekräfta slutresultatet. Följ körningen i GitHub innan du försöker igen."
                }
            } catch {
                await MainActor.run {
                    if dispatchAccepted {
                        item.patchStatusRawValue = item.patchWorkflowRunID == nil ? "dispatched" : "running"
                        statusMessage = "GitHub tog emot godkännandet, men statuskontrollen misslyckades: \(error.localizedDescription). Kontrollera den befintliga körningen innan du försöker igen."
                    } else {
                        item.patchStatusRawValue = "pending"
                        statusMessage = "Kunde inte skicka godkännandet: \(error.localizedDescription)"
                    }
                    item.updatedAt = .now
                }
            }
        }
    }
    private func refreshPendingApprovedPatchStatuses() {
        for item in byteWorkItems where item.patchStatusRawValue == "dispatched" || item.patchStatusRawValue == "running" {
            refreshApprovedPatchStatus(for: item)
        }
    }

    private func refreshApprovedPatchStatus(for item: ByteWorkItem) {
        guard item.patchStatusRawValue == "dispatched" || item.patchStatusRawValue == "running" else { return }
        guard let token = GitHubTokenStore.read() else {
            statusMessage = "GitHub-token saknas. Spara den först."
            return
        }
        guard refreshingPatchItemIDs.insert(item.id).inserted else { return }
        statusMessage = "Kontrollerar GitHub-status…"
        Task {
            defer {
                Task { @MainActor in
                    refreshingPatchItemIDs.remove(item.id)
                }
            }
            do {
                // Once GitHub has supplied a run ID, poll that exact run. Do not
                // rediscover it by title/date: that can miss older or delayed runs.
                if let runID = item.patchWorkflowRunID {
                    let status = try await GitHubWorkflowClient.fetchRunStatus(runID: runID, token: token)
                    await MainActor.run {
                        item.patchWorkflowURL = status.url?.absoluteString ?? item.patchWorkflowURL
                        item.patchStatusRawValue = status.status == "completed"
                            ? (status.conclusion == "success" ? "completed" : "failed")
                            : "running"
                        item.updatedAt = .now
                    }
                    guard status.status == "completed" else {
                        await MainActor.run {
                            statusMessage = "GitHub-körningen pågår fortfarande. Statusen har uppdaterats."
                        }
                        return
                    }
                    let succeeded = status.conclusion == "success"
                    let failureDetails = succeeded ? nil : try? await GitHubWorkflowClient.fetchFailureSummary(runID: runID, token: token)
                    let pullRequestURL = succeeded
                        ? await GitHubWorkflowClient.fetchPullRequestURL(repository: item.projectRepository, runID: runID, title: item.title, token: token)
                        : nil
                    await MainActor.run {
                        item.patchFailureDetails = failureDetails
                        item.patchPullRequestURL = pullRequestURL?.absoluteString ?? item.patchPullRequestURL
                        statusMessage = succeeded
                            ? "GitHub-arbetsflödet lyckades. PR-länken har uppdaterats."
                            : "GitHub-arbetsflödet misslyckades. Felorsaken har hämtats om den var tillgänglig."
                        modelContext.insert(DEVHUBNotification(
                            title: succeeded ? "Byte har skapat ett PR-förslag" : "Byte kunde inte skapa PR",
                            message: statusMessage ?? "",
                            category: succeeded ? "assistant" : "issue",
                            destinationURL: status.url?.absoluteString
                        ))
                    }
                    return
                }

                guard let startedAt = item.patchDispatchedAt else {
                    await MainActor.run {
                        statusMessage = "Tidpunkten för godkännandet saknas. Körningen kan inte matchas säkert."
                    }
                    return
                }
                let result = try await GitHubWorkflowClient.waitForApprovedPatchRun(
                    startedAt: startedAt,
                    expectedTitle: String(item.title.prefix(120)),
                    token: token
                ) { runID, runURL in
                    await MainActor.run {
                        item.patchWorkflowRunID = runID
                        item.patchWorkflowURL = runURL?.absoluteString
                        item.patchStatusRawValue = "running"
                        item.updatedAt = .now
                    }
                }
                let succeeded = result.message.contains("lyckades")
                let failureDetails = succeeded ? nil : try? await GitHubWorkflowClient.fetchFailureSummary(runID: result.id, token: token)
                let pullRequestURL = succeeded
                    ? await GitHubWorkflowClient.fetchPullRequestURL(repository: item.projectRepository, runID: result.id, title: item.title, token: token)
                    : nil
                await MainActor.run {
                    item.patchStatusRawValue = succeeded ? "completed" : "failed"
                    item.patchFailureDetails = failureDetails
                    item.patchPullRequestURL = pullRequestURL?.absoluteString ?? item.patchPullRequestURL
                    item.patchWorkflowURL = result.url?.absoluteString ?? item.patchWorkflowURL
                    item.updatedAt = .now
                    statusMessage = result.message
                    modelContext.insert(DEVHUBNotification(
                        title: succeeded ? "Byte har skapat ett PR-förslag" : "Byte kunde inte skapa PR",
                        message: result.message,
                        category: succeeded ? "assistant" : "issue",
                        destinationURL: result.url?.absoluteString
                    ))
                }
            } catch {
                await MainActor.run {
                    statusMessage = "Statusen kunde inte bekräftas: \(error.localizedDescription)"
                }
            }
        }
    }

    private func refreshPatchFailureDetails(for item: ByteWorkItem, runID: Int) {
        guard item.patchFailureDetails == nil else { return }
        guard let token = GitHubTokenStore.read() else {
            statusMessage = "GitHub-token saknas. Spara den först."
            return
        }
        statusMessage = "Hämtar felorsak från GitHub…"
        Task {
            do {
                let details = try await GitHubWorkflowClient.fetchFailureSummary(runID: runID, token: token)
                await MainActor.run {
                    item.patchFailureDetails = details
                    item.updatedAt = .now
                    statusMessage = "Felorsaken har hämtats och sparats."
                }
            } catch {
                await MainActor.run {
                    statusMessage = "Felorsaken kunde inte hämtas: \\(error.localizedDescription)"
                }
            }
        }
    }

    private func importByteTaskProposals(json: String, repository: String? = nil) {
        guard let data = json.data(using: .utf8),
              let rows = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            statusMessage = "Bytes uppgiftsförslag kunde inte läsas."
            return
        }
        let sourceRepository = repository ?? analysisRepository
        let repo = sourceRepository.split(separator: "/").last.map(String.init) ?? sourceRepository
        let projectID: String
        switch repo {
        case "fam": projectID = "familjen"
        case "watch": projectID = "watchlist"
        case "vill": projectID = "antikspanaren"
        case "project-orbit": projectID = "regnvakt"
        case "hem": projectID = "hemma"
        default: projectID = "devhub"
        }
        var added = 0
        for row in rows.prefix(8) {
            guard let title = row["title"] as? String else { continue }
            let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !cleanTitle.isEmpty,
                  !projectTasks.contains(where: {
                      $0.projectID == projectID &&
                      $0.title.localizedCaseInsensitiveCompare(cleanTitle) == .orderedSame
                  }) else { continue }
            let milestoneTitle = row["milestone"] as? String ?? ""
            let milestone = projectMilestones.first {
                $0.projectID == projectID &&
                $0.title.localizedCaseInsensitiveCompare(milestoneTitle) == .orderedSame
            }
            let weight = max(1, min(row["weight"] as? Int ?? 1, 5))
            modelContext.insert(ProjectTaskItem(
                projectID: projectID,
                title: cleanTitle,
                weight: weight,
                milestoneID: milestone?.id
            ))
            added += 1
        }
        statusMessage = added == 0
            ? "Inga nya uppgifter att lägga till."
            : "Byte lade till \(added) uppgifter. De är inte markerade som klara."
    }

    private func submitTask() {
        guard let token = GitHubTokenStore.read() else {
            statusMessage = "GitHub-token saknas. Spara den först."
            return
        }
        let prompt = task.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }
        focusedField = nil
        analysisRepository = selectedRepository
        // A selected conversation must never silently become a fresh task because
        // the user changed the global work-mode setting in the meantime.
        let previousResponseID = continuingFromResponseID
        let submissionMode = previousResponseID == nil ? workMode : "collaborate"
        let queueItem = ByteWorkItem(projectRepository: selectedRepository, title: prompt, workMode: submissionMode)
        queueItem.conversationResponseID = previousResponseID
        modelContext.insert(queueItem)
        let queueItemID = queueItem.id
        isSending = true
        statusMessage = nil
        workflowURL = nil
        analysisText = nil
        analysisTaskProposalJSON = nil
        runStatus = "Skickar uppdraget till GitHub…"
        let startedAt = Date()
        Task {
            do {
                try await GitHubWorkflowClient.dispatch(repository: selectedRepository, task: prompt, workMode: submissionMode, previousResponseID: previousResponseID, token: token)
                await MainActor.run {
                    if let item = byteWorkItems.first(where: { $0.id == queueItemID }) {
                        item.statusRawValue = "running"
                        item.updatedAt = .now
                    }
                    statusMessage = "Uppdraget är mottaget. Väntar på AI-analysen…"
                    task = ""
                    continuingFromResponseID = nil
                }
                let result = try await GitHubWorkflowClient.waitForRun(startedAt: startedAt, expectedTask: prompt, token: token) { runID, runURL in
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
                        let responseID = extractResponseID(from: text)
                        let proposalJSON = extractTaskProposalJSON(from: text)
                        let cleanText = cleanAnalysis(from: text, responseID: responseID)
                        await MainActor.run {
                            analysisText = cleanText
                            analysisTaskProposalJSON = proposalJSON
                            if let item = byteWorkItems.first(where: { $0.id == queueItemID }) {
                                applyUsage(from: text, to: item)
                                item.analysisText = cleanText
                                item.taskProposalJSON = proposalJSON
                                item.patchPreview = extractPatchPreview(from: text)
                                item.baseCommitSHA = extractBaseSHA(from: text)
                                item.conversationResponseID = responseID
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

enum GitHubTokenStore {
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
        let display_title: String?
    }

    struct RunStatus { let status: String; let conclusion: String?; let url: URL? }

    private struct JobsResponse: Decodable { let jobs: [WorkflowJob] }
    private struct WorkflowJob: Decodable {
        let name: String
        let conclusion: String?
        let steps: [WorkflowStep]?
    }
    private struct WorkflowStep: Decodable {
        let name: String
        let conclusion: String?
    }

    static func fetchFailureSummary(runID: Int, token: String) async throws -> String {
        let endpoint = URL(string: "https://api.github.com/repos/72cbbw422f-alt/devh/actions/runs/\(runID)/jobs?per_page=50")!
        var request = URLRequest(url: endpoint)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw WorkflowError.statusCheck
        }
        let jobs = try JSONDecoder().decode(JobsResponse.self, from: data).jobs
        let failures = jobs.flatMap { job -> [String] in
            let failedSteps = (job.steps ?? []).filter { $0.conclusion == "failure" }.map { $0.name }
            if failedSteps.isEmpty && job.conclusion == "failure" {
                return ["\(job.name): jobbet misslyckades (ingen enskild felande steg rapporterades)."]
            }
            return failedSteps.map { "\(job.name) → \($0)" }
        }
        return failures.isEmpty
            ? "GitHub markerade körningen som misslyckad men rapporterade inget specifikt felsteg. Öppna körningen för fullständiga loggar."
            : failures.joined(separator: "\n")
    }

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
        expectedTask: String,
        token: String,
        onRunFound: @escaping (Int, URL?) async -> Void
    ) async throws -> RunResult {
        let formatter = ISO8601DateFormatter()
        var matchedRun: WorkflowRun?
        for _ in 0..<40 {
            try await Task.sleep(nanoseconds: 3_000_000_000)
            var request = URLRequest(url: URL(string: "https://api.github.com/repos/72cbbw422f-alt/devh/actions/workflows/ai-assistant.yml/runs?per_page=10")!)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { throw WorkflowError.statusCheck }
            let runs = try JSONDecoder().decode(RunsResponse.self, from: data).workflow_runs
            if matchedRun == nil {
                matchedRun = runs.first(where: {
                    $0.event == "workflow_dispatch" &&
                    $0.display_title == expectedTask &&
                    (formatter.date(from: $0.created_at) ?? .distantPast) >= startedAt.addingTimeInterval(-10)
                })
                if let run = matchedRun {
                    await onRunFound(run.id, URL(string: run.html_url))
                }
            }
            guard let run = matchedRun else { continue }
            let status = try await fetchRunStatus(runID: run.id, token: token)
            if status.status == "completed" {
                let message = status.conclusion == "success"
                    ? "AI-analysen lyckades! Resultatet finns i GitHub-körningens Summary."
                    : "AI-körningen avslutades med fel (\(status.conclusion ?? "okänt fel")). Öppna körningen för detaljer."
                return RunResult(id: run.id, message: message, url: status.url ?? URL(string: run.html_url))
            }
        }
        throw WorkflowError.timeout
    }


    static func waitForApprovedPatchRun(
        startedAt: Date,
        expectedTitle: String,
        token: String,
        onRunFound: @escaping (Int, URL?) async -> Void
    ) async throws -> RunResult {
        let formatter = ISO8601DateFormatter()
        var matchedRun: WorkflowRun?
        for _ in 0..<40 {
            try await Task.sleep(nanoseconds: 3_000_000_000)
            var request = URLRequest(url: URL(string: "https://api.github.com/repos/72cbbw422f-alt/devh/actions/workflows/apply-byte-patch.yml/runs?per_page=10")!)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { throw WorkflowError.statusCheck }
            let runs = try JSONDecoder().decode(RunsResponse.self, from: data).workflow_runs
            if matchedRun == nil {
                matchedRun = runs.first(where: {
                    $0.event == "workflow_dispatch" &&
                    $0.display_title == expectedTitle &&
                    (formatter.date(from: $0.created_at) ?? .distantPast) >= startedAt.addingTimeInterval(-10)
                })
                if let run = matchedRun {
                    await onRunFound(run.id, URL(string: run.html_url))
                }
            }
            guard let run = matchedRun else { continue }
            let status = try await fetchRunStatus(runID: run.id, token: token)
            if status.status == "completed" {
                let message = status.conclusion == "success"
                    ? "GitHub-arbetsflödet lyckades och PR-förslaget ska nu finnas i projektets Pull requests."
                    : "GitHub-arbetsflödet misslyckades (\(status.conclusion ?? "okänt fel")). Öppna körningen för loggar och felorsak."
                return RunResult(id: run.id, message: message, url: status.url ?? URL(string: run.html_url))
            }
        }
        throw WorkflowError.timeout
    }

    private struct PullRequest: Decodable {
        let html_url: String
    }

    static func fetchPullRequestURL(repository: String, runID: Int, title: String, token: String) async -> URL? {
        let slugBase = title.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
        let asciiSlug = String(slugBase.map { character -> Character in
            character.unicodeScalars.allSatisfy { $0.isASCII } && (character.isLetter || character.isNumber) ? character : "-"
        })
        let slug = String(asciiSlug.split(separator: "-", omittingEmptySubsequences: true).joined(separator: "-").prefix(32))
        let branch = "byte/approved-\(runID)-\(slug.isEmpty ? "change" : slug)"
        let components = repository.split(separator: "/")
        guard components.count == 2 else { return nil }
        var urlComponents = URLComponents(string: "https://api.github.com/repos/\(repository)/pulls")!
        urlComponents.queryItems = [
            URLQueryItem(name: "state", value: "all"),
            URLQueryItem(name: "head", value: "\(components[0]):\(branch)"),
            URLQueryItem(name: "per_page", value: "1")
        ]
        guard let url = urlComponents.url else { return nil }
        for _ in 0..<5 {
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
            guard let (data, response) = try? await URLSession.shared.data(for: request),
                  let http = response as? HTTPURLResponse, http.statusCode == 200,
                  let pullRequests = try? JSONDecoder().decode([PullRequest].self, from: data),
                  let first = pullRequests.first,
                  let pullURL = URL(string: first.html_url) else {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                continue
            }
            return pullURL
        }
        return nil
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

    static func dispatchApprovedPatch(repository: String, baseSHA: String, patch: String, title: String, token: String) async throws {
        let endpoint = URL(string: "https://api.github.com/repos/72cbbw422f-alt/devh/actions/workflows/apply-byte-patch.yml/dispatches")!
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["ref": "main", "inputs": ["project_repository": repository, "base_sha": baseSHA, "patch": patch, "task_title": String(title.prefix(120))]])
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw WorkflowError.invalidResponse }
        guard (200...299).contains(http.statusCode) else {
            let detail = String(data: data, encoding: .utf8) ?? ""
            if http.statusCode == 401 || http.statusCode == 403 { throw WorkflowError.permission }
            throw WorkflowError.http(http.statusCode, detail)
        }
    }
    static func dispatch(repository: String, task: String, workMode: String, previousResponseID: String?, token: String) async throws {
        let url = URL(string: "https://api.github.com/repos/72cbbw422f-alt/devh/actions/workflows/ai-assistant.yml/dispatches")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "ref": "main",
            "inputs": ["project_repository": repository, "task": task, "work_mode": workMode, "previous_response_id": previousResponseID ?? ""]
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
