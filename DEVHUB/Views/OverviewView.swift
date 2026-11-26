import SwiftUI

struct OverviewView: View {
    let projects: [StudioProject]
    let onSelect: (StudioProject) -> Void

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    private var activeCount: Int { projects.filter { $0.status == .active }.count }
    private var averageProgress: Double {
        guard !projects.isEmpty else { return 0 }
        return projects.reduce(0) { $0 + $1.progress } / Double(projects.count)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                studioHero
                LazyVGrid(columns: columns, spacing: 12) {
                    MetricCard(title: "AKTIVA PROJEKT", value: "\(activeCount)", note: "Pågående utveckling", symbol: "square.stack.3d.up")
                    MetricCard(title: "GENOMSNITTLIGT FRAMSTEG", value: "\(Int(averageProgress * 100))%", note: "Baserat på projektens planerade framsteg", symbol: "chart.donut")
                    MetricCard(title: "INTÄKTER / MÅNAD", value: "Ej anslutet", note: "Ingen betalningskälla ansluten", symbol: "arrow.up.right")
                    MetricCard(title: "SENASTE RELEASE", value: "Ej ansluten", note: "Releaseinformation hämtas från GitHub i ett senare steg", symbol: "shippingbox")
                }
                HStack {
                    SectionHeading(eyebrow: "DIN ARBETSPLATS", title: "Projektöversikt")
                    Spacer()
                    NavigationLink("Alla projekt") {
                        ProjectListView(projects: projects, onSelect: onSelect)
                    }
                    .font(.caption.weight(.semibold))
                    .tint(StudioTheme.accent)
                }
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(projects.prefix(6)) { project in
                        Button { onSelect(project) } label: { ProjectCard(project: project) }
                            .buttonStyle(.plain)
                    }
                }
                SectionHeading(eyebrow: "SENASTE", title: "Senaste aktivitet")
                IntegrationEmptyState()
            }
            .padding(18)
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
        .background(StudioTheme.background.ignoresSafeArea())
        .navigationTitle("DEVHUB")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                .font(.caption.weight(.semibold))
                .tracking(1.2)
                .foregroundStyle(StudioTheme.muted)
            Text("Bygg något fantastiskt.")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(StudioTheme.text)
            Text("Allt ditt utvecklingsarbete. På ett ställe.")
                .font(.subheadline)
                .foregroundStyle(StudioTheme.secondaryText)
        }
    }

    private var studioHero: some View {
        VStack(alignment: .leading, spacing: 17) {
            HStack {
                Label("STUDIOÖVERSIKT", systemImage: "sparkles")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.1)
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                Image(systemName: "command")
                    .font(.title2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
            }
            Text("Dina idéer.\\nI rörelse.")
                .font(.system(size: 27, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(activeCount) aktiva projekt")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("Samlad projektstatus")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
                ZStack {
                    Circle().stroke(.white.opacity(0.2), lineWidth: 5)
                    Circle()
                        .trim(from: 0, to: averageProgress)
                        .stroke(.white, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(averageProgress * 100))%")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .frame(width: 54, height: 54)
            }
        }
        .padding(19)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(
                    colors: [Color(hex: "302A78"), Color(hex: "5146B8"), Color(hex: "2866B5")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(.white.opacity(0.08))
                        .frame(width: 150, height: 150)
                        .blur(radius: 2)
                        .offset(x: 45, y: -65)
                }
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.12), lineWidth: 1))
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let note: String
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                Text(title)
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.7)
                    .foregroundStyle(StudioTheme.muted)
                Spacer(minLength: 2)
                Image(systemName: symbol)
                    .foregroundStyle(StudioTheme.accent)
            }
            Text(value)
                .font(.system(size: 23, weight: .bold, design: .rounded))
                .foregroundStyle(StudioTheme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(note)
                .font(.system(size: 10))
                .foregroundStyle(StudioTheme.muted)
                .lineLimit(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(StudioTheme.surface, in: RoundedRectangle(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(StudioTheme.border, lineWidth: 1))
    }
}

struct SectionHeading: View {
    let eyebrow: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(eyebrow)
                .font(.system(size: 9, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(StudioTheme.muted)
            Text(title)
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(StudioTheme.text)
        }
    }
}

struct IntegrationEmptyState: View {
    var body: some View {
        VStack(spacing: 9) {
            Image(systemName: "arrow.triangle.branch")
                .font(.title2)
                .foregroundStyle(StudioTheme.accent)
            Text("Aktivitetsflödet väntar")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(StudioTheme.text)
            Text("När GitHub-aktiviteten kopplas in visas commits, pull requests, issues och releaser här.")
                .font(.caption)
                .foregroundStyle(StudioTheme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(25)
        .background(StudioTheme.surface, in: RoundedRectangle(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(StudioTheme.border, lineWidth: 1))
    }
}
