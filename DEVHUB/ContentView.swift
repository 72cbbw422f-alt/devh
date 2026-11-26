import SwiftUI
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
    @State private var selection:StudioTab = .overview
    @State private var projects = StudioProject.samples
    @State private var selectedProject:StudioProject?
    var body: some View {
        TabView(selection:$selection) {
            NavigationStack {
                OverviewView(projects:projects) { selectedProject = $0 }
                    .navigationDestination(item:$selectedProject) { ProjectDetailView(project:$0) }
            }.tabItem { Label(StudioTab.overview.rawValue,systemImage:StudioTab.overview.symbol) }.tag(StudioTab.overview)
            NavigationStack {
                ProjectListView(projects:projects) { selectedProject = $0 }
                    .navigationDestination(item:$selectedProject) { ProjectDetailView(project:$0) }
            }.tabItem { Label(StudioTab.projects.rawValue,systemImage:StudioTab.projects.symbol) }.tag(StudioTab.projects)
            NavigationStack { AssistantView() }
                .tabItem { Label(StudioTab.assistant.rawValue,systemImage:StudioTab.assistant.symbol) }.tag(StudioTab.assistant)
            ForEach([StudioTab.activity,.roadmap,.revenue,.analytics]) { tab in
                NavigationStack { PlaceholderView(tab:tab) }
                    .tabItem { Label(tab.rawValue,systemImage:tab.symbol) }.tag(tab)
            }
        }.tint(StudioTheme.accent).preferredColorScheme(.dark)
    }
}