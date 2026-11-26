import SwiftUI
import SwiftData

enum StudioTab: String, CaseIterable, Identifiable, Hashable {
    case overview = "Översikt"
    case projects = "Projekt"
    case assistant = "Assistent"
    case activity = "Utveckling"
    case roadmap = "Roadmap"
    case revenue = "Ekonomi"
    case analytics = "Analys"
    case notifications = "Notiser"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .overview: "square.grid.2x2"
        case .projects: "square.stack.3d.up"
        case .assistant: "sparkles"
        case .activity: "arrow.triangle.branch"
        case .roadmap: "map"
        case .revenue: "chart.line.uptrend.xyaxis"
        case .analytics: "chart.bar"
        case .notifications: "bell"
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query(sort: \StudioProjectRecord.createdAt) private var storedProjects: [StudioProjectRecord]
    @Query private var storedTasks: [ProjectTaskItem]
    @Query private var storedMilestones: [ProjectMilestoneItem]
    @State private var selection: StudioTab = .overview
    @State private var selectedProject: StudioProject?
    @State private var showingAddProject = false

    private var projects: [StudioProject] {
        storedProjects.filter { !$0.isArchived }.map { record in
            var project = record.project
            let tasks = storedTasks.filter { $0.projectID == record.id }
            let totalWeight = tasks.reduce(0) { $0 + max(1, min($1.weight ?? 1, 5)) }
            let completedWeight = tasks.filter(\.isCompleted).reduce(0) { $0 + max(1, min($1.weight ?? 1, 5)) }
            project.progress = totalWeight == 0 ? 0 : Double(completedWeight) / Double(totalWeight)
            return project
        }
    }

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                iPadLayout
            } else {
                iPhoneLayout
            }
        }
        .tint(StudioTheme.accent)
        .preferredColorScheme(.dark)
        .toolbarBackground(StudioTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(StudioTheme.background, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .background(StudioTheme.background.ignoresSafeArea())
        .sheet(isPresented: $showingAddProject) {
            AddProjectView { project in
                modelContext.insert(StudioProjectRecord(project: project))
                selectedProject = project
            }
        }
        .task { seedProjectsIfNeeded() }
    }

    private var iPadLayout: some View {
        NavigationSplitView {
            List {
                Section("ARBETSPLATS") {
                    ForEach([StudioTab.overview, .projects, .assistant]) { tab in
                        sidebarRow(for: tab)
                    }
                }
                Section("UTVECKLING") {
                    ForEach([StudioTab.activity, .roadmap]) { tab in
                        sidebarRow(for: tab)
                    }
                }
                Section("INSIKTER") {
                    ForEach([StudioTab.revenue, .analytics, .notifications]) { tab in
                        sidebarRow(for: tab)
                    }
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .background(StudioTheme.background)
            .navigationTitle("DEVHUB")
            .navigationSplitViewColumnWidth(min: 220, ideal: 250, max: 300)
        } detail: {
            NavigationStack {
                tabContent(for: selection)
                    .navigationTitle(selection.rawValue)
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationDestination(item: $selectedProject) {
                        ProjectDetailView(project: $0)
                    }
                    .toolbar {
                        if selection == .projects {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button {
                                    showingAddProject = true
                                } label: {
                                    Image(systemName: "plus").fontWeight(.semibold)
                                }
                                .accessibilityLabel("Lägg till projekt")
                            }
                        }
                    }
            }
            .background(StudioTheme.background)
        }
        .navigationSplitViewStyle(.balanced)
    }

    private func sidebarRow(for tab: StudioTab) -> some View {
        Button {
            selection = tab
            selectedProject = nil
        } label: {
            Label(tab.rawValue, systemImage: tab.symbol)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(selection == tab ? StudioTheme.text : StudioTheme.secondaryText)
        .listRowBackground(selection == tab ? StudioTheme.elevated : Color.clear)
    }

    private var iPhoneLayout: some View {
        TabView(selection: $selection) {
            ForEach(StudioTab.allCases) { tab in
                NavigationStack {
                    tabContent(for: tab)
                        .navigationDestination(item: $selectedProject) {
                            ProjectDetailView(project: $0)
                        }
                        .toolbar {
                            if tab == .projects {
                                ToolbarItem(placement: .topBarTrailing) {
                                    Button {
                                        showingAddProject = true
                                    } label: {
                                        Image(systemName: "plus").fontWeight(.semibold)
                                    }
                                    .accessibilityLabel("Lägg till projekt")
                                }
                            }
                        }
                }
                .tabItem { Label(tab.rawValue, systemImage: tab.symbol) }
                .tag(tab)
            }
        }
    }

    @ViewBuilder
    private func tabContent(for tab: StudioTab) -> some View {
        switch tab {
        case .overview:
            OverviewView(projects: projects) { selectedProject = $0 }
        case .projects:
            ProjectListView { selectedProject = $0 }
        case .assistant:
            AssistantView()
        case .activity:
            PlaceholderView(tab: tab)
        case .roadmap:
            RoadmapView(projects: projects) { selectedProject = $0 }
        case .revenue:
            OpenAIEconomyView()
        case .analytics:
            AnalyticsView()
        case .notifications:
            NotificationCenterView()
        }
    }

    private func seedProjectsIfNeeded() {
        if storedProjects.isEmpty {
            for project in StudioProject.samples {
                modelContext.insert(StudioProjectRecord(project: project))
            }
        } else if !storedProjects.contains(where: { $0.id == "watchlist" }),
                  let watchlist = StudioProject.samples.first(where: { $0.id == "watchlist" }) {
            modelContext.insert(StudioProjectRecord(project: watchlist))
        }

        // Seed every project's tracking data up front so overview percentages
        // are meaningful before the user opens each project detail screen.
        let projectsToSeed = StudioProject.samples + storedProjects.map(\\.project)
        var seenProjectIDs = Set<String>()
        for project in projectsToSeed where seenProjectIDs.insert(project.id).inserted {
            let milestones = storedMilestones.filter { $0.projectID == project.id }
            var milestoneRecords = milestones.sorted { $0.sortOrder < $1.sortOrder }
            if milestoneRecords.isEmpty {
                for (index, title) in milestoneTitles(for: project.id).enumerated() {
                    let item = ProjectMilestoneItem(projectID: project.id, title: title, sortOrder: index)
                    modelContext.insert(item)
                    milestoneRecords.append(item)
                }
            }

            let tasks = storedTasks.filter { $0.projectID == project.id }
            if tasks.isEmpty {
                for (index, title) in taskTitles(for: project.id).enumerated() where index < milestoneRecords.count {
                    modelContext.insert(ProjectTaskItem(
                        projectID: project.id,
                        title: title,
                        weight: index == 0 ? 3 : 2,
                        milestoneID: milestoneRecords[index].id
                    ))
                }
            } else {
                for (index, task) in tasks.filter({ $0.milestoneID == nil }).enumerated()
                    where index < milestoneRecords.count {
                    task.milestoneID = milestoneRecords[index].id
                }
            }
        }
    }

    private func milestoneTitles(for projectID: String) -> [String] {
        switch projectID {
        case "familjen": ["Grundstruktur och navigering", "Familjekalender", "Delade inköpslistor", "Inbjudan och synkronisering"]
        case "watchlist": ["Grundläggande bibliotek", "Progress-lista", "TMDB och metadata", "Import och synkronisering"]
        case "antikspanaren": ["Datamodell och sök", "Auktionskällor", "Bevakningar", "Pris- och objekthistorik"]
        case "regnvakt": ["Väderöversikt", "SMHI-varningar", "Radar och kartlager", "Bakgrundsnotiser"]
        case "hemma": ["Appskal och rum", "HomeKit-anslutning", "Tillbehör och scener", "Automationer"]
        default: ["Projektöversikt och AI", "GitHub-arbetsflöde", "Milstolpar och uppgifter", "Byggstatus och distribution"]
        }
    }

    private func taskTitles(for projectID: String) -> [String] {
        switch projectID {
        case "familjen": ["Bygg grundstruktur och navigering", "Färdigställ familjekalendern", "Verifiera delade listor", "Testa inbjudan och synkronisering"]
        case "watchlist": ["Bygg bibliotekets grund", "Färdigställ progress-listan", "Verifiera TMDB och metadata", "Testa import och synkronisering"]
        case "antikspanaren": ["Bygg datamodell och sök", "Integrera auktionskällor", "Skapa bevakningar", "Verifiera pris- och objekthistorik"]
        case "regnvakt": ["Färdigställ väderöversikten", "Verifiera SMHI-varningar", "Stabilisera radar och kartlager", "Testa bakgrundsnotiser"]
        case "hemma": ["Bygg appskal och rum", "Verifiera HomeKit-anslutning", "Visa tillbehör och scener", "Testa automationer"]
        default: ["Färdigställ projektöversikt och AI", "Verifiera GitHub-arbetsflöde", "Bygg milstolpar och uppgifter", "Verifiera byggstatus och distribution"]
        }
    }
}
