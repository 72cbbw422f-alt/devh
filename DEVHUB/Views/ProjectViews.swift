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
    @State private var showArchived = false
    @State private var editingRecord: StudioProjectRecord?
    @State private var showingEditor = false

    private var visibleRecords: [StudioProjectRecord] {
        records.filter { $0.isArchived == showArchived }
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
                            ProgressView(value: record.progress).tint(Color(hex: record.accent))
                        }
                        Spacer()
                        Text("\(Int(record.progress * 100))%")
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
    @State private var newTaskTitle = ""

    init(project: StudioProject) {
        self.project = project
        let projectID = project.id
        _storedTasks = Query(
            filter: #Predicate<ProjectTaskItem> { $0.projectID == projectID },
            sort: \ProjectTaskItem.createdAt
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
        case "familjen": ["Färdigställ kalenderflödet", "Verifiera delade listor", "Testa inbjudningsflödet"]
        case "watchlist": ["Förfina progress-listan", "Kontrollera metadataimport", "Testa statusfilter"]
        case "antikspanaren": ["Kartlägg källornas API:er", "Normalisera objektsdata", "Planera bevakningsmotor"]
        case "regnvakt": ["Felsök varningsmatchning", "Verifiera radarens tidsstämplar", "Testa notiser i bakgrunden"]
        case "hemma": ["Verifiera HomeKit-entitlements", "Bygg grundläggande rumsvy", "Testa tillbehörsstatus"]
        default: ["Färdigställ projektdetaljer", "Koppla GitHub-status", "Dokumentera bygg- och releaseflödet"]
        }
    }

    private var completedCount: Int { storedTasks.filter(\.isCompleted).count }
    private var githubRepositoryPath: String { project.repository.contains("/") ? project.repository : "72cbbw422f-alt/\(project.repository)" }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ProjectCard(project: project)

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeading(eyebrow: "PROJEKTETS RIKTNING", title: "Milstolpar")
                    ForEach(Array(milestones.enumerated()), id: \.offset) { index, milestone in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle().fill(index == 0 ? StudioTheme.accent.opacity(0.2) : StudioTheme.elevated).frame(width: 30, height: 30)
                                if index == 0 {
                                    Image(systemName: "checkmark").font(.caption.bold()).foregroundStyle(StudioTheme.accentCyan)
                                } else {
                                    Text("\(index + 1)").font(.caption.bold()).foregroundStyle(StudioTheme.muted)
                                }
                            }
                            Text(milestone).font(.subheadline.weight(.medium)).foregroundStyle(StudioTheme.text)
                            Spacer()
                            if index == 0 { Text("BAS").font(.system(size: 8, weight: .bold)).foregroundStyle(StudioTheme.accentCyan) }
                        }
                        if index < milestones.count - 1 { Divider().overlay(StudioTheme.border).padding(.leading, 42) }
                    }
                }
                .padding(16)
                .background(StudioTheme.surface, in: RoundedRectangle(cornerRadius: 17))
                .overlay(RoundedRectangle(cornerRadius: 17).stroke(StudioTheme.border, lineWidth: 1))

                VStack(alignment: .leading, spacing: 13) {
                    HStack {
                        SectionHeading(eyebrow: "ATT GÖRA", title: "Arbetslista")
                        Spacer()
                        Text("\(completedCount)/\(storedTasks.count)")
                            .font(.caption.monospacedDigit().bold()).foregroundStyle(StudioTheme.accentCyan)
                    }
                    if storedTasks.isEmpty {
                        Text("Förbereder projektets första uppgifter…")
                            .font(.caption).foregroundStyle(StudioTheme.muted)
                    } else {
                        ForEach(storedTasks) { task in
                            Button { task.isCompleted.toggle() } label: {
                                HStack(spacing: 11) {
                                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .font(.title3).foregroundStyle(task.isCompleted ? StudioTheme.accentCyan : StudioTheme.muted)
                                    Text(task.title)
                                        .font(.subheadline)
                                        .foregroundStyle(task.isCompleted ? StudioTheme.muted : StudioTheme.text)
                                        .strikethrough(task.isCompleted, color: StudioTheme.muted)
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
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

                VStack(alignment: .leading, spacing: 10) {
                    SectionHeading(eyebrow: "KÄLLKOD", title: "GitHub")
                    Text(githubRepositoryPath)
                        .font(.system(.body, design: .monospaced)).foregroundStyle(StudioTheme.secondaryText)
                    Link("Öppna repository", destination: URL(string: "https://github.com/\(githubRepositoryPath)")!)
                        .font(.subheadline.weight(.semibold)).tint(StudioTheme.accent)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(StudioTheme.surface, in: RoundedRectangle(cornerRadius: 17))
                .overlay(RoundedRectangle(cornerRadius: 17).stroke(StudioTheme.border, lineWidth: 1))
                Text("Uppgifter sparas lokalt på enheten med SwiftData. GitHub-synkronisering av milstolpar planeras separat.")
                    .font(.caption).foregroundStyle(StudioTheme.muted)
            }
            .padding(18)
            .frame(maxWidth: 850)
            .frame(maxWidth: .infinity)
        }
        .background(StudioTheme.background.ignoresSafeArea())
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
        .task { seedTasksIfNeeded() }
    }

    private func addTask() {
        let title = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        modelContext.insert(ProjectTaskItem(projectID: project.id, title: title))
        newTaskTitle = ""
    }

    private func seedTasksIfNeeded() {
        guard storedTasks.isEmpty else { return }
        for title in suggestedTasks {
            modelContext.insert(ProjectTaskItem(projectID: project.id, title: title))
        }
    }
}
