import SwiftUI

struct RoadmapView: View {
    let projects: [StudioProject]
    let onSelect: (StudioProject) -> Void

    private var activeProjects: [StudioProject] {
        projects.sorted {
            if $0.status == .active && $1.status != .active { return true }
            if $0.status != .active && $1.status == .active { return false }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private var averageProgress: Int {
        guard !projects.isEmpty else { return 0 }
        return Int(projects.reduce(0) { $0 + $1.progress } / Double(projects.count) * 100)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                summary
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeading(eyebrow: "PROJEKT FÖR PROJEKT", title: "Nästa milstolpar")
                    ForEach(activeProjects) { project in
                        Button { onSelect(project) } label: {
                            roadmapCard(project)
                        }
                        .buttonStyle(.plain)
                    }
                }
                Text("Milstolparna visar projektens nuvarande planering. De är inte automatiskt synkroniserade med GitHub ännu.")
                    .font(.caption)
                    .foregroundStyle(StudioTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(28)
            .frame(maxWidth: 1080)
            .frame(maxWidth: .infinity)
        }
        .background(StudioTheme.background.ignoresSafeArea())
        .navigationTitle("Roadmap")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("RIKTNING OCH PRIORITERING")
                .font(.system(size: 9, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(StudioTheme.accentCyan)
            Text("Från idé till release.")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(StudioTheme.text)
            Text("En samlad vy över nästa steg i alla dina projekt.")
                .font(.subheadline)
                .foregroundStyle(StudioTheme.secondaryText)
        }
    }

    private var summary: some View {
        HStack(spacing: 12) {
            summaryMetric(value: "\(projects.count)", label: "PROJEKT", symbol: "square.stack.3d.up")
            summaryMetric(value: "\(projects.filter { $0.status == .active }.count)", label: "AKTIVA", symbol: "bolt.fill")
            summaryMetric(value: "\(averageProgress)%", label: "SNITTFRAMSTEG", symbol: "chart.pie")
        }
    }

    private func summaryMetric(value: String, label: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(StudioTheme.accent)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(StudioTheme.text)
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .tracking(0.7)
                .foregroundStyle(StudioTheme.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(13)
        .background(StudioTheme.surface, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(StudioTheme.border, lineWidth: 1))
    }

    private func roadmapCard(_ project: StudioProject) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 10) {
                Image(systemName: project.symbol)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(hex: project.accent))
                    .frame(width: 36, height: 36)
                    .background(Color(hex: project.accent).opacity(0.15), in: RoundedRectangle(cornerRadius: 11))
                VStack(alignment: .leading, spacing: 3) {
                    Text(project.name)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(StudioTheme.text)
                    Text(project.platform + " · " + project.category)
                        .font(.caption2)
                        .foregroundStyle(StudioTheme.muted)
                }
                Spacer()
                Text(project.status.rawValue.uppercased())
                    .font(.system(size: 8, weight: .bold))
                    .tracking(0.4)
                    .foregroundStyle(project.status == .active ? StudioTheme.accentCyan : StudioTheme.muted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(StudioTheme.elevated, in: Capsule())
            }

            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text("NÄSTA MILSTOLPE")
                        .font(.system(size: 8, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(StudioTheme.muted)
                    Spacer()
                    Text("\(Int(project.progress * 100))%")
                        .font(.caption.monospacedDigit().weight(.bold))
                        .foregroundStyle(StudioTheme.text)
                }
                Text(project.nextMilestone)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(StudioTheme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(StudioTheme.elevated)
                        Capsule()
                            .fill(LinearGradient(colors: [Color(hex: project.accent), StudioTheme.accent], startPoint: .leading, endPoint: .trailing))
                            .frame(width: proxy.size.width * min(max(project.progress, 0), 1))
                    }
                }
                .frame(height: 5)
            }

            HStack {
                Text("Öppna projektplan")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(StudioTheme.accent)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(StudioTheme.accent)
            }
        }
        .padding(15)
        .background(StudioTheme.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(StudioTheme.border, lineWidth: 1))
    }
}
