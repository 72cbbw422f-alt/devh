import SwiftUI

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
                Text(project.platform + " · " + project.category)
                    .lineLimit(1)
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
                        .fill(LinearGradient(
                            colors: [Color(hex: project.accent), StudioTheme.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: max(5, proxy.size.width * min(max(project.progress, 0), 1)))
                }
            }
            .frame(height: 5)

            HStack(spacing: 5) {
                Image(systemName: "arrow.up.right.square")
                Text(project.repository)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 8, weight: .bold))
            }
            .font(.system(size: 9, design: .monospaced))
            .foregroundStyle(StudioTheme.muted)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(
                    colors: [StudioTheme.surface, StudioTheme.surface.opacity(0.82)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
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
    let projects: [StudioProject]
    let onSelect: (StudioProject) -> Void

    var body: some View {
        List(projects) { project in
            Button { onSelect(project) } label: {
                HStack(spacing: 12) {
                    Image(systemName: project.symbol)
                        .foregroundStyle(Color(hex: project.accent))
                        .frame(width: 40, height: 40)
                        .background(StudioTheme.elevated, in: RoundedRectangle(cornerRadius: 12))
                    VStack(alignment: .leading, spacing: 5) {
                        Text(project.name)
                            .font(.headline)
                            .foregroundStyle(StudioTheme.text)
                        Text(project.repository)
                            .font(.caption)
                            .foregroundStyle(StudioTheme.muted)
                        ProgressView(value: project.progress)
                            .tint(StudioTheme.accent)
                    }
                    Spacer()
                    Text("\(Int(project.progress * 100))%")
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .foregroundStyle(StudioTheme.accent)
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(StudioTheme.surface)
            .listRowSeparatorTint(StudioTheme.border)
        }
        .scrollContentBackground(.hidden)
        .background(StudioTheme.background)
        .navigationTitle("Projekt")
    }
}

struct ProjectDetailView: View {
    let project: StudioProject

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ProjectCard(project: project)
                SectionHeading(eyebrow: "NÄSTA MILSTOLPE", title: project.nextMilestone)
                VStack(alignment: .leading, spacing: 10) {
                    Label("GitHub-repository", systemImage: "chevron.left.forwardslash.chevron.right")
                        .font(.headline)
                        .foregroundStyle(StudioTheme.text)
                    Text("72cbbw422f-alt/\(project.repository)")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(StudioTheme.muted)
                    Link("Öppna på GitHub", destination: URL(string: "https://github.com/72cbbw422f-alt/\(project.repository)")!)
                        .font(.subheadline.weight(.semibold))
                        .tint(StudioTheme.accent)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(StudioTheme.surface, in: RoundedRectangle(cornerRadius: 15))
                .overlay(RoundedRectangle(cornerRadius: 15).stroke(StudioTheme.border, lineWidth: 1))
                IntegrationEmptyState()
            }
            .padding(18)
        }
        .background(StudioTheme.background.ignoresSafeArea())
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
