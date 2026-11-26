import SwiftUI
import SwiftData

struct ProjectCard: View {
    let project: StudioProject

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: project.symbol)
                    .font(.headline)
                    .foregroundStyle(Color(hex: project.accent))
                    .frame(width: 38, height: 38)
                    .background(Color(hex: project.accent).opacity(0.16), in: RoundedRectangle(cornerRadius: 12))
                Spacer()
                Text(project.status.rawValue.uppercased())
                    .font(.system(size: 8, weight: .bold))
                    .tracking(0.5)
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(statusColor.opacity(0.13), in: Capsule())
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(StudioTheme.text)
                Text(project.subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(StudioTheme.secondaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(minHeight: 28, alignment: .topLeading)
            }
            HStack {
                Text(project.platform + " · " + project.category).lineLimit(1)
                Spacer(minLength: 4)
                Text("\(Int(project.progress * 100))%")
                    .fontWeight(.bold)
                    .foregroundStyle(StudioTheme.text)
            }
            .font(.system(size: 9))
            .foregroundStyle(StudioTheme.muted)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(StudioTheme.elevated)
                    Capsule()
                        .fill(LinearGradient(colors: [Color(hex: project.accent), StudioTheme.accent], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(5, proxy.size.width * min(max(project.progress, 0), 1)))
                }
            }
            .frame(height: 5)
            HStack(spacing: 5) {
                Image(systemName: "arrow.up.right.square")
                Text(project.repository).lineLimit(1)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 8, weight: .bold))
            }
            .font(.system(size: 9, design: .monospaced))
            .foregroundStyle(StudioTheme.muted)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(colors: [StudioTheme.surface, StudioTheme.surface.opacity(0.82)], startPoint: .topLeading, endPoint: .bottomTrailing))
        }
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(StudioTheme.border, lineWidth: 1))
    }

    private var statusColor: Color {
        switch project.status {
        case .active: StudioTheme.accentCyan
        case .planning: Color(hex: "E5B86B")
        case .paused: StudioTheme.muted
        case .released: Color(hex: "6BCB9A")
        }
    }
}

struct ProjectListView: View {
    let onSelect: (StudioProject) -> Void
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StudioProjectRecord.createdAt) private var records: [StudioProjectRecord]
    @Query private var projectTasks: [ProjectTaskItem]
    @State private var showArchived = false
    @State private var editingRecord: StudioProjectRecord?
    @State private var showingEditor = false

    private var visibleRecords: [StudioProjectRecord] {
        records.filter { $0.isArchived == showArchived }
    }

    private func calculatedProgress(for record: StudioProjectRecord) -> Double {
        let tasks = projectTasks.filter { $0.projectID == record.id }
        let totalWeight = tasks.reduce(0) { $0 + max(1, min($1.weight ?? 1, 5)) }
        let completedWeight = tasks.filter(\.isCompleted).reduce(0) {
            $0 + max(1, min($1.weight ?? 1, 5))
        }
        return totalWeight == 0 ? 0 : Double(completedWeight) / Double(totalWeight)
    }

    var body: some View {
        List {
            ForEach(visibleRecords) { record in
                Button { onSelect(record.project) } label: {
                    HStack(spacing: 12) {
                        Image(systemName: record.symbol)
                            .foregroundStyle(Color(hex: record.accent))
                            .frame(width: 40, height: 40)
                            .background(StudioTheme.elevated, in: RoundedRectangle(cornerRadius: 12))
                        VStack(alignment: .leading, spacing: 5) {
                            Text(record.name).font(.headline).foregroundStyle(StudioTheme.text)
                            Text(record.repository.isEmpty ? record.platform : record.repository)
                                .font(.caption).foregroundStyle(StudioTheme.muted)
                            ProgressView(value: calculatedProgress(for: record)).tint(Color(hex: record.accent))
                        }
                        Spacer()
                        Text("\(Int(calculatedProgress(for: record) * 100))%")
                            .font(.caption.monospacedDigit().weight(.semibold))
                            .foregroundStyle(StudioTheme.accent)
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(StudioTheme.surface)
                .listRowSeparatorTint(StudioTheme.border)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button {
                        record.isArchived.toggle()
                    } label: {
                        Label(record.isArchived ? "Återställ" : "Arkivera",
                              systemImage: record.isArchived ? "tray.and.arrow.up" : "archivebox")
                    }
                    .tint(record.isArchived ? .green : .orange)
                    Button {
                        editingRecord = record
                        showingEditor = true
                    } label: {
                        Label("Redigera", systemImage: "pencil")
                    }
                    .tint(.indigo)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(StudioTheme.background)
        .navigationTitle(showArchived ? "Arkiverade projekt" : "Projekt")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showArchived.toggle()
                } label: {
                    Image(systemName: showArchived ? "tray.full" : "archivebox")
                }
                .accessibilityLabel(showArchived ? "Visa aktiva projekt" : "Visa arkiverade projekt")
            }
        }
        .sheet(isPresented: $showingEditor, onDismiss: { editingRecord = nil }) {
            if let record = editingRecord {
                AddProjectView(project: record.project) { updated in
                    record.name = updated.name
                    record.subtitle = updated.subtitle
                    record.platform = updated.platform
                    record.category = updated.category
                    record.repository = updated.repository
                    record.statusRawValue = updated.status.rawValue
                    record.symbol = updated.symbol
                    record.accent = updated.accent
                    record.nextMilestone = updated.nextMilestone
                }
            }
        }
    }
}

struct ProjectDetailView: View {
    let project: StudioProject
    @Environment(\.modelContext) private var modelContext
    @Query private var storedTasks: [ProjectTaskItem]
    @Query private var storedMilestones: [ProjectMilestoneItem]
    @State private var newTaskTitle = ""
    @State private var selectedMilestoneID = ""
    @State private var showingPRVerification = false
    @State private var verificationPRInput = ""
    @State private var verificationTaskID: String?
    @State private var isVerifyingPR = false
    @State private var verificationMessage: String?

    init(project: StudioProject) {
        self.project = project
        let projectID = project.id
        _storedTasks = Query(
            filter: #Predicate<ProjectTaskItem> { $0.projectID == projectID },
            sort: \ProjectTaskItem.createdAt
        )
        _storedMilestones = Query(
            filter: #Predicate<ProjectMilestoneItem> { $0.projectID == projectID },
            sort: \ProjectMilestoneItem.sortOrder
        )
    }

    private var milestones: [String] {
        switch project.id {
        case "familjen": ["Grundstruktur och navigering", "Familjekalender", "Delade inköpslistor", "Inbjudan och synkronisering"]
        case "watchlist": ["Grundläggande bibliotek", "Progress-lista", "TMDB och metadata", "Import och synkronisering"]
        case "antikspanaren": ["Datamodell och sök", "Auktionskällor", "Bevakningar", "Pris- och objekthistorik"]
        case "regnvakt": ["Väderöversikt", "SMHI-varningar", "Radar och kartlager", "Bakgrundsnotiser"]
        case "hemma": ["Appskal och rum", "HomeKit-anslutning", "Tillbehör och scener", "Automationer"]
        default: ["Projektöversikt och AI", "GitHub-arbetsflöde", "Milstolpar och uppgifter", "Byggstatus och distribution"]
        }
    }

    private var suggestedTasks: [String] {
        switch project.id {
        case "familjen": ["Bygg grundstruktur och navigering", "Färdigställ familjekalendern", "Verifiera delade listor", "Testa inbjudan och synkronisering"]
        case "watchlist": ["Bygg bibliotekets grund", "Färdigställ progress-listan", "Verifiera TMDB och metadata", "Testa import och synkronisering"]
        case "antikspanaren": ["Bygg datamodell och sök", "Integrera auktionskällor", "Skapa bevakningar", "Verifiera pris- och objekthistorik"]
        case "regnvakt": ["Färdigställ väderöversikten", "Verifiera SMHI-varningar", "Stabilisera radar och kartlager", "Testa bakgrundsnotiser"]
        case "hemma": ["Bygg appskal och rum", "Verifiera HomeKit-anslutning", "Visa tillbehör och scener", "Testa automationer"]
        default: ["Färdigställ projektöversikt och AI", "Verifiera GitHub-arbetsflöde", "Bygg milstolpar och uppgifter", "Verifiera byggstatus och distribution"]
        }
    }

    private var completedCount: Int { storedTasks.filter(\.isCompleted).count }
    private var totalWeight: Int { storedTasks.reduce(0) { $0 + max(1, min($1.weight ?? 1, 5)) } }
    private var completedWeight: Int {
        storedTasks.filter(\.isCompleted).reduce(0) { $0 + max(1, min($1.weight ?? 1, 5)) }
    }
    private var calculatedProgress: Double {
        totalWeight == 0 ? 0 : Double(completedWeight) / Double(totalWeight)
    }
    private var completedMilestoneCount: Int {
        storedMilestones.filter { milestone in
            let linked = storedTasks.filter { $0.milestoneID == milestone.id }
            return linked.isEmpty ? milestone.isCompleted : linked.allSatisfy { $0.isCompleted }
        }.count
    }
    private var displayProject: StudioProject {
        var value = project
        value.progress = calculatedProgress
        return value
    }
    private var githubRepositoryPath: String { project.repository.contains("/") ? project.repository : "72cbbw422f-alt/\(project.repository)" }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ProjectCard(project: displayProject)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        SectionHeading(eyebrow: "PROJEKTETS RIKTNING", title: "Milstolpar")
                        Spacer()
                        Text("\(completedMilestoneCount)/\(storedMilestones.count)")
                            .font(.caption.monospacedDigit().bold())
                            .foregroundStyle(StudioTheme.accentCyan)
                    }
                    ForEach(storedMilestones) { milestone in
                        let linkedTasks = storedTasks.filter { $0.milestoneID == milestone.id }
                        let isDone = linkedTasks.isEmpty ? milestone.isCompleted : linkedTasks.allSatisfy { $0.isCompleted }
                        Button {
                            if linkedTasks.isEmpty { milestone.isCompleted.toggle() }
                            else { for task in linkedTasks { task.isCompleted = !isDone } }
                            milestone.updatedAt = .now
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(isDone ? StudioTheme.accentCyan : StudioTheme.muted)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(milestone.title)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(isDone ? StudioTheme.muted : StudioTheme.text)
                                        .strikethrough(isDone, color: StudioTheme.muted)
                                    if !linkedTasks.isEmpty {
                                        Text("\(linkedTasks.filter { $0.isCompleted }.count)/\(linkedTasks.count) uppgifter")
                                            .font(.system(size: 9)).foregroundStyle(StudioTheme.muted)
                                    }
                                }
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
                .background(StudioTheme.surface, in: RoundedRectangle(cornerRadius: 17))
                .overlay(RoundedRectangle(cornerRadius: 17).stroke(StudioTheme.border, lineWidth: 1))

                VStack(alignment: .leading, spacing: 13) {
                    HStack {
                        SectionHeading(eyebrow: "ATT GÖRA", title: "Arbetslista")
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(Int(calculatedProgress * 100))%")
                                .font(.caption.monospacedDigit().bold()).foregroundStyle(StudioTheme.accentCyan)
                            Text("\(completedCount)/\(storedTasks.count) uppgifter")
                                .font(.system(size: 9)).foregroundStyle(StudioTheme.muted)
                        }
                    }
                    if storedTasks.isEmpty {
                        Text("Lägg till arbetsuppgifter för att börja mäta framsteg.")
                            .font(.caption).foregroundStyle(StudioTheme.muted)
                    } else {
                        ForEach(storedTasks) { task in
                            HStack(spacing: 11) {
                                Image(systemName: task.statusSymbol)
                                    .font(.title3)
                                    .foregroundStyle(task.statusRawValue == "verified" ? .green : (task.isCompleted ? StudioTheme.accentCyan : StudioTheme.muted))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(task.title)
                                        .font(.subheadline)
                                        .foregroundStyle(task.isCompleted ? StudioTheme.muted : StudioTheme.text)
                                        .strikethrough(task.isCompleted, color: StudioTheme.muted)
                                    Text("\(task.statusLabel) · Vikt \(max(1, min(task.weight ?? 1, 5))) av 5")
                                        .font(.system(size: 9)).foregroundStyle(StudioTheme.muted)
                                    if let prURL = task.verificationPRURL, let url = URL(string: prURL) {
                                        Link("Verifierad via GitHub PR", destination: url)
                                            .font(.system(size: 9, weight: .medium))
                                            .foregroundStyle(.green)
                                    }
                                }
                                Spacer()
                                Menu {
                                    Button("Föreslagen") {
                                        task.statusRawValue = "proposed"
                                        task.isCompleted = false
                                    }
                                    Button("Pågår") {
                                        task.statusRawValue = "inProgress"
                                        task.isCompleted = false
                                    }
                                    Button("Klar – manuellt") {
                                        task.statusRawValue = "completed"
                                        task.isCompleted = true
                                    }
                                    Button("Verifiera via GitHub PR…") {
                                        verificationTaskID = task.id
                                        verificationPRInput = task.verificationPRURL ?? ""
                                        showingPRVerification = true
                                    }
                                    Divider()
                                    ForEach(1...5, id: \.self) { weight in
                                        Button("Vikt \(weight)") { task.weight = weight }
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                        .font(.caption).foregroundStyle(StudioTheme.muted)
                                        .padding(8)
                                }
                            }
                        }
                    }
                    if !storedMilestones.isEmpty {
                        Picker("Koppla till milstolpe", selection: $selectedMilestoneID) {
                            ForEach(storedMilestones) { milestone in
                                Text(milestone.title).tag(milestone.id)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(StudioTheme.accentCyan)
                    }
                    HStack(spacing: 9) {
                        TextField("Lägg till en uppgift…", text: $newTaskTitle)
                            .font(.subheadline)
                            .textInputAutocapitalization(.sentences)
                            .padding(11)
                            .background(StudioTheme.elevated, in: RoundedRectangle(cornerRadius: 10))
                        Button(action: addTask) {
                            Image(systemName: "plus")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(width: 42, height: 42)
                                .background(StudioTheme.accent, in: RoundedRectangle(cornerRadius: 10))
                        }
                        .disabled(newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding(16)
                .background(StudioTheme.surface, in: RoundedRectangle(cornerRadius: 17))
                .overlay(RoundedRectangle(cornerRadius: 17).stroke(StudioTheme.border, lineWidth: 1))

                GitHubRepositoryStatusView(repository: githubRepositoryPath)
                Text("Manuellt klarmarkerade uppgifter räknas i framstegen. GitHub-verifiering kräver en mergad PR och att samtliga registrerade GitHub-kontroller har godkänts. Uppgiftsdata sparas lokalt på enheten.")
                    .font(.caption).foregroundStyle(StudioTheme.muted)
            }
            .padding(18)
            .frame(maxWidth: 1080)
            .frame(maxWidth: .infinity)
        }
        .background(StudioTheme.background.ignoresSafeArea())
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
        .task { seedProjectTrackingIfNeeded() }
        .alert("Verifiera GitHub-PR", isPresented: $showingPRVerification) {
            TextField("https://github.com/ägare/repo/pull/123", text: $verificationPRInput)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button("Avbryt", role: .cancel) { verificationTaskID = nil }
            Button("Kontrollera och verifiera") { verifyTaskPullRequest() }
                .disabled(verificationPRInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isVerifyingPR)
        } message: {
            Text("Uppgiften blir verifierad först när PR:en är mergad och alla GitHub-kontroller är klara med resultatet success.")
        }
        .alert("GitHub-verifiering", isPresented: Binding(get: { verificationMessage != nil }, set: { if !$0 { verificationMessage = nil } })) {
            Button("OK") { verificationMessage = nil }
        } message: {
            Text(verificationMessage ?? "")
        }
    }


    private func verifyTaskPullRequest() {
        guard let taskID = verificationTaskID,
              let task = storedTasks.first(where: { $0.id == taskID }) else { return }
        let prURL = verificationPRInput.trimmingCharacters(in: .whitespacesAndNewlines)
        isVerifyingPR = true
        Task {
            do {
                let result = try await GitHubRepositoryService().verifyMergedPullRequest(url: prURL, expectedRepository: githubRepositoryPath)
                await MainActor.run {
                    task.verificationPRURL = result.pullRequestURL.absoluteString
                    task.verificationCommitSHA = result.commitSHA
                    task.verificationWorkflowURL = result.workflowURL.absoluteString
                    task.statusRawValue = "verified"
                    task.isCompleted = true
                    isVerifyingPR = false
                    verificationTaskID = nil
                    verificationMessage = "Godkänd! PR:en är mergad och GitHub-kontrollerna är godkända. Uppgiften är nu verifierad."
                }
            } catch {
                await MainActor.run {
                    isVerifyingPR = false
                    verificationMessage = error.localizedDescription
                }
            }
        }
    }

    private func addTask() {
        let title = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        modelContext.insert(ProjectTaskItem(projectID: project.id, title: title, milestoneID: selectedMilestoneID.isEmpty ? storedMilestones.first?.id : selectedMilestoneID))
        newTaskTitle = ""
    }

    private func seedProjectTrackingIfNeeded() {
        let milestoneRecords: [ProjectMilestoneItem]
        if storedMilestones.isEmpty {
            milestoneRecords = milestones.enumerated().map { index, title in
                let item = ProjectMilestoneItem(projectID: project.id, title: title, sortOrder: index)
                modelContext.insert(item)
                return item
            }
        } else {
            milestoneRecords = storedMilestones
        }
        if storedTasks.isEmpty {
            for (index, title) in suggestedTasks.enumerated() where index < milestoneRecords.count {
                modelContext.insert(ProjectTaskItem(projectID: project.id, title: title, weight: index == 0 ? 3 : 2, milestoneID: milestoneRecords[index].id))
            }
        } else {
            let unlinkedTasks = storedTasks.filter { $0.milestoneID == nil }
            for (index, task) in unlinkedTasks.enumerated() where index < milestoneRecords.count {
                task.milestoneID = milestoneRecords[index].id
            }
        }
        if selectedMilestoneID.isEmpty { selectedMilestoneID = milestoneRecords.first?.id ?? "" }
    }
}
