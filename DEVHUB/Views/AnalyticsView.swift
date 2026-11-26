import SwiftUI
import SwiftData

struct AnalyticsView: View {
    @Query(sort: \\StudioProjectRecord.createdAt) private var storedProjects: [StudioProjectRecord]
    @Query(sort: \\ProjectTaskItem.createdAt) private var allTasks: [ProjectTaskItem]

    private var projects: [StudioProjectRecord] {
        storedProjects.filter { !$0.isArchived }
    }

    private var projectIDs: Set<String> {
        Set(projects.map(\\.id))
    }

    private var tasks: [ProjectTaskItem] {
        allTasks.filter { projectIDs.contains($0.projectID) }
    }

    private var completedTasks: Int {
        tasks.filter(\\.isCompleted).count
    }

    private var taskCompletion: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(completedTasks) / Double(tasks.count)
    }

    private var averagePlannedProgress: Double {
        guard !projects.isEmpty else { return 0 }
        return projects.reduce(0) { $0 + $1.progress } / Double(projects.count)
    }

    private var statusCounts: [(ProjectStatus, Int)] {
        ProjectStatus.allCases.map { status in
            (status, projects.filter { $0.status == status }.count)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                if projects.isEmpty {
                    emptyState
                } else {
                    overviewMetrics
                    taskProgressSection
                    statusSection
                    projectProgressSection
                    footnote
                }
            }
            .padding(18)
            .frame(maxWidth: 850)
            .frame(maxWidth: .infinity)
        }
        .background(StudioTheme.background.ignoresSafeArea())
        .navigationTitle("Analys")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("FAKTA FRÅN DINA PROJEKT")
                .font(.system(size: 9, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(StudioTheme.accentCyan)
            Text("Se hur arbetet går.")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(StudioTheme.text)
            Text("En överblick baserad på projekt och uppgifter som faktiskt är sparade i DEVHUB.")
                .font(.subheadline)
                .foregroundStyle(StudioTheme.secondaryText)
        }
    }

    private var overviewMetrics: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            metricCard(value: "\\(projects.count)", label: "AKTIVA PROJEKT", symbol: "square.stack.3d.up")
            metricCard(value: "\\(Int(averagePlannedProgress * 100))%", label: "PLANERAT SNITT", symbol: "chart.pie")
            metricCard(value: "\\(tasks.count)", label: "SPARADE UPPGIFTER", symbol: "checklist")
            metricCard(value: "\\(completedTasks)", label: "AVKLARADE", symbol: "checkmark.circle")
        }
    }

    private func metricCard(value: String, label: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Image(systemName: symbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(StudioTheme.accent)
            Text(value)
                .font(.system(size: 25, weight: .bold, design: .rounded))
                .foregroundStyle(StudioTheme.text)
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(StudioTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .background(StudioTheme.surface, in: RoundedRectangle(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(StudioTheme.border, lineWidth: 1))
    }

    private var taskProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading(eyebrow: "GENOMFÖRANDE", title: "Arbetsuppgifter")
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text(tasks.isEmpty ? "Inga uppgifter ännu" : "\\(Int(taskCompletion * 100))% avklarat")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(StudioTheme.text)
                    Spacer()
                    Text("\\(completedTasks) av \\(tasks.count)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(StudioTheme.muted)
                }
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(StudioTheme.elevated)
                        Capsule()
                            .fill(LinearGradient(colors: [StudioTheme.accent, StudioTheme.accentCyan], startPoint: .leading, endPoint: .trailing))
                            .frame(width: proxy.size.width * taskCompletion)
                    }
                }
                .frame(height: 8)
                Text("Beräknat från checklistor i projektens detaljvyer.")
                    .font(.caption2)
                    .foregroundStyle(StudioTheme.muted)
            }
            .padding(15)
            .background(StudioTheme.surface, in: RoundedRectangle(cornerRadius: 15))
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(StudioTheme.border, lineWidth: 1))
        }
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading(eyebrow: "FÖRDELNING", title: "Projektstatus")
            VStack(spacing: 13) {
                ForEach(statusCounts, id: \\.0.id) { status, count in
                    HStack(spacing: 10) {
                        Text(status.rawValue)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(StudioTheme.secondaryText)
                        Spacer()
                        GeometryReader { proxy in
                            ZStack(alignment: .leading) {
                                Capsule().fill(StudioTheme.elevated)
                                Capsule().fill(status == .active ? StudioTheme.accentCyan : StudioTheme.accent)
                                    .frame(width: proxy.size.width * (projects.isEmpty ? 0 : CGFloat(count) / CGFloat(projects.count)))
                            }
                        }
                        .frame(width: 90, height: 6)
                        Text("\\(count)")
                            .font(.caption.monospacedDigit().weight(.bold))
                            .foregroundStyle(StudioTheme.text)
                            .frame(width: 20, alignment: .trailing)
                    }
                }
            }
            .padding(15)
            .background(StudioTheme.surface, in: RoundedRectangle(cornerRadius: 15))
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(StudioTheme.border, lineWidth: 1))
        }
    }

    private var projectProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading(eyebrow: "PLANERING", title: "Framsteg per projekt")
            VStack(spacing: 15) {
                ForEach(projects.sorted { $0.progress > $1.progress }, id: \\.id) { project in
                    VStack(alignment: .leading, spacing: 7) {
                        HStack {
                            Text(project.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(StudioTheme.text)
                            Spacer()
                            Text("\\(Int(project.progress * 100))%")
                                .font(.caption.monospacedDigit().weight(.bold))
                                .foregroundStyle(StudioTheme.secondaryText)
                        }
                        GeometryReader { proxy in
                            ZStack(alignment: .leading) {
                                Capsule().fill(StudioTheme.elevated)
                                Capsule().fill(Color(hex: project.accent))
                                    .frame(width: proxy.size.width * min(max(project.progress, 0), 1))
                            }
                        }
                        .frame(height: 6)
                    }
                }
            }
            .padding(15)
            .background(StudioTheme.surface, in: RoundedRectangle(cornerRadius: 15))
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(StudioTheme.border, lineWidth: 1))
        }
    }

    private var footnote: some View {
        Text("Planerat framsteg är projektets manuella planeringsvärde. Det är separat från avklarade checklistuppgifter. Arkiverade projekt räknas inte med.")
            .font(.caption2)
            .foregroundStyle(StudioTheme.muted)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 30))
                .foregroundStyle(StudioTheme.accent)
            Text("Ingen projektdata ännu")
                .font(.headline)
                .foregroundStyle(StudioTheme.text)
            Text("Lägg till ett projekt så börjar analysen fyllas med verkliga siffror.")
                .font(.subheadline)
                .foregroundStyle(StudioTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(StudioTheme.surface, in: RoundedRectangle(cornerRadius: 16))
    }
}
