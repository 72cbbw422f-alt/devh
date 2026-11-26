import SwiftUI
import SwiftData

enum StudioTab: String, CaseIterable, Identifiable {
    case overview="Översikt", projects="Projekt", assistant="Assistent", activity="Utveckling", roadmap="Roadmap", revenue="Ekonomi", analytics="Analys"
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
            ForEach([StudioTab.activity,.roadmap,.revenue,.analytics]) { tab in
                NavigationStack {
                    if tab == .roadmap {
                        RoadmapView(projects: projects) { selectedProject = $0 }
                    } else if tab == .analytics {
                        AnalyticsView()
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
        .sheet(isPresented: $showingAddProject) {
            AddProjectView { project in
                modelContext.insert(StudioProjectRecord(project: project))
                selectedProject = project
            }
        }
        .task { seedProjectsIfNeeded() }
    }

    private func seedProjectsIfNeeded() {
        // Watchlist was explicitly retired. Remove its old local seed and checklist during migration.
        for project in storedProjects where project.id == "watchlist" {
            modelContext.delete(project)
        }
        for task in storedTasks where task.projectID == "watchlist" {
            modelContext.delete(task)
        }

        guard storedProjects.isEmpty else { return }
        for project in StudioProject.samples {
            modelContext.insert(StudioProjectRecord(project: project))
        }
    }
}
