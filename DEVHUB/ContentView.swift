import SwiftUI
import SwiftData

enum StudioTab: String, CaseIterable, Identifiable {
    case overview="Översikt", projects="Projekt", assistant="Assistent", activity="Utveckling", roadmap="Roadmap", revenue="Ekonomi", analytics="Analys", notifications="Notiser"
    var id:String { rawValue }
    var symbol:String {
        switch self {
        case .overview:"square.grid.2x2"
        case .projects:"square.stack.3d.up"
        case .assistant:"sparkles"
        case .activity:"arrow.triangle.branch"
        case .roadmap:"map"
        case .revenue:"chart.line.uptrend.xyaxis"
        case .analytics:"chart.bar"
        case .notifications:"bell"
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StudioProjectRecord.createdAt) private var storedProjects: [StudioProjectRecord]
    @Query private var storedTasks: [ProjectTaskItem]
    @State private var selection:StudioTab = .overview
    @State private var selectedProject:StudioProject?
    @State private var showingAddProject = false

    private var projects: [StudioProject] { storedProjects.filter { !$0.isArchived }.map(\.project) }

    var body: some View {
        TabView(selection:$selection) {
            NavigationStack {
                OverviewView(projects:projects) { selectedProject = $0 }
                    .navigationDestination(item:$selectedProject) { ProjectDetailView(project:$0) }
            }.tabItem { Label(StudioTab.overview.rawValue,systemImage:StudioTab.overview.symbol) }.tag(StudioTab.overview)
            NavigationStack {
                ProjectListView { selectedProject = $0 }
                    .navigationDestination(item:$selectedProject) { ProjectDetailView(project:$0) }
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button { showingAddProject = true } label: {
                                Image(systemName: "plus").fontWeight(.semibold)
                            }
                            .accessibilityLabel("Lägg till projekt")
                        }
                    }
            }.tabItem { Label(StudioTab.projects.rawValue,systemImage:StudioTab.projects.symbol) }.tag(StudioTab.projects)
            NavigationStack { AssistantView() }
                .tabItem { Label(StudioTab.assistant.rawValue,systemImage:StudioTab.assistant.symbol) }.tag(StudioTab.assistant)
            ForEach([StudioTab.activity,.roadmap,.revenue,.analytics,.notifications]) { tab in
                NavigationStack {
                    if tab == .roadmap {
                        RoadmapView(projects: projects) { selectedProject = $0 }
                    } else if tab == .analytics {
                        AnalyticsView()
                    } else if tab == .notifications {
                        NotificationCenterView()
                    } else {
                        PlaceholderView(tab: tab)
                    }
                }
                .navigationDestination(item: $selectedProject) { ProjectDetailView(project: $0) }
                .tabItem { Label(tab.rawValue, systemImage: tab.symbol) }.tag(tab)
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

    private func seedProjectsIfNeeded() {
        if storedProjects.isEmpty {
            for project in StudioProject.samples {
                modelContext.insert(StudioProjectRecord(project: project))
            }
            return
        }

        // Restore Watchlist if an earlier app build removed its local seed.
        if !storedProjects.contains(where: { $0.id == "watchlist" }) {
            if let watchlist = StudioProject.samples.first(where: { $0.id == "watchlist" }) {
                modelContext.insert(StudioProjectRecord(project: watchlist))
            }
        }
    }
}
