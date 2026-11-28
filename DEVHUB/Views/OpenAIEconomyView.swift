import SwiftUI
import Charts

struct OpenAIEconomyView: View {
    @State private var snapshot: OpenAICostSnapshot?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var lastFetchAt: Date?
    @AppStorage("openAI.monthlyBudgetUSD") private var monthlyBudgetUSD = 25.0

    private let billingURL = URL(string: "https://platform.openai.com/settings/organization/billing/overview")!

    private var budgetProgress: Double {
        guard monthlyBudgetUSD > 0, let snapshot else { return 0 }
        return min(snapshot.monthToDateUSD / monthlyBudgetUSD, 1)
    }

    private var budgetLevel: Int {
        guard let snapshot, monthlyBudgetUSD > 0 else { return 0 }
        let percentage = snapshot.monthToDateUSD / monthlyBudgetUSD
        if percentage >= 1 { return 100 }
        if percentage >= 0.9 { return 90 }
        if percentage >= 0.75 { return 75 }
        return 0
    }

    private var budgetWarning: Bool { budgetLevel >= 75 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                if let snapshot {
                    monthSummary(snapshot)
                    budgetCard(snapshot)
                    dailyChart(snapshot)
                    projectSection(snapshot)
                    lineItemSection(snapshot)
                    updateMetadata(snapshot)
                } else if isLoading {
                    ProgressView("Hämtar OpenAI-kostnader…")
                        .frame(maxWidth: .infinity).padding(30)
                } else {
                    sectionCard(title: "Kostnadsrapporten är inte tillgänglig ännu", subtitle: "OpenAI API-rapport · konfiguration krävs") {
                        Text(errorMessage ?? "Ingen kostnadsrapport har hämtats ännu.")
                            .font(.subheadline).foregroundStyle(StudioTheme.secondaryText)
                        Divider().overlay(StudioTheme.border)
                        Label("1. Spara en GitHub-token i Assistent-fliken", systemImage: "key.horizontal")
                            .font(.subheadline.weight(.medium)).foregroundStyle(StudioTheme.text)
                        Text("Tokenen behöver kunna läsa innehåll i DEVHUB-repot.")
                            .font(.caption).foregroundStyle(StudioTheme.muted)
                        Label("2. Lägg till OPENAI_ADMIN_KEY som GitHub Secret", systemImage: "lock.shield")
                            .font(.subheadline.weight(.medium)).foregroundStyle(StudioTheme.text)
                        Text("Det krävs en OpenAI-organisationsnyckel med behörighet att läsa kostnadsdata. En vanlig API-nyckel eller GitHub-token räcker inte.")
                            .font(.caption).foregroundStyle(StudioTheme.muted)
                        Label("3. Kör arbetsflödet OpenAI cost snapshot", systemImage: "play.circle")
                            .font(.subheadline.weight(.medium)).foregroundStyle(StudioTheme.text)
                        Text("När rapporten har publicerats till grenen openai-metrics kan DEVHUB läsa in diagram, projektfördelning och kostnadsposter.")
                            .font(.caption).foregroundStyle(StudioTheme.muted)
                    }
                }

                sectionCard(title: "ChatGPT och API är separata", subtitle: "Viktigt om kostnaderna") {
                    Text("Den här rapporten visar endast API-förbrukning från OpenAI Platform. Din ChatGPT-prenumeration ingår inte och debiteras separat.")
                        .font(.subheadline).foregroundStyle(StudioTheme.secondaryText)
                    Link(destination: billingURL) {
                        Label("Öppna OpenAI Billing", systemImage: "arrow.up.right.square")
                            .font(.subheadline.weight(.semibold)).foregroundStyle(StudioTheme.accent)
                    }
                }

                Button {
                    Task { await loadSnapshot() }
                } label: {
                    HStack {
                        if isLoading { ProgressView().tint(.white) }
                        else { Image(systemName: "arrow.clockwise") }
                        Text(isLoading ? "Uppdaterar…" : "Uppdatera kostnader")
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity).padding(14)
                    .background(StudioTheme.accent, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
                }
                .disabled(isLoading)
                if let errorMessage, snapshot != nil {
                    Text(errorMessage).font(.caption).foregroundStyle(.orange)
                }
            }
            .padding(28)
            .frame(maxWidth: 1080)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(StudioTheme.background.ignoresSafeArea())
        .navigationTitle("AI-ekonomi")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadSnapshot() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Label("OPENAI · API-KOSTNADER", systemImage: "chart.xyaxis.line")
                .font(.caption.bold()).foregroundStyle(StudioTheme.accent)
            Text("AI-ekonomi")
                .font(.system(size: 29, weight: .bold, design: .rounded))
                .foregroundStyle(StudioTheme.text)
            Text("Följ förbrukning, projektkostnader och din egen månadsbudget.")
                .font(.subheadline).foregroundStyle(StudioTheme.secondaryText)
        }
    }

    private func monthSummary(_ snapshot: OpenAICostSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("FÖRBRUKNING DENNA MÅNAD")
                .font(.caption.bold()).tracking(0.8).foregroundStyle(StudioTheme.secondaryText)
            Text(formattedCurrency(snapshot.monthToDateUSD, currency: snapshot.currency))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(StudioTheme.text)
            HStack {
                Label("Sedan \(snapshot.monthStart)", systemImage: "calendar")
                Spacer()
                Text(snapshot.currency).font(.caption.bold())
            }
            .font(.caption).foregroundStyle(StudioTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(StudioTheme.surface, in: RoundedRectangle(cornerRadius: 17))
        .overlay(RoundedRectangle(cornerRadius: 17).stroke(StudioTheme.border, lineWidth: 1))
    }

    private func budgetCard(_ snapshot: OpenAICostSnapshot) -> some View {
        sectionCard(title: "Månadsbudget", subtitle: "Lokal budget i USD · ändras bara på den här enheten") {
            HStack(alignment: .firstTextBaseline) {
                Text(formattedCurrency(snapshot.monthToDateUSD, currency: snapshot.currency))
                    .font(.title2.bold().monospacedDigit()).foregroundStyle(StudioTheme.text)
                Spacer()
                Text("av")
                    .font(.caption).foregroundStyle(StudioTheme.muted)
                Text(formattedCurrency(monthlyBudgetUSD, currency: "USD"))
                    .font(.headline.monospacedDigit()).foregroundStyle(StudioTheme.secondaryText)
            }
            ProgressView(value: budgetProgress)
                .tint(budgetWarning ? .orange : StudioTheme.accentCyan)
            HStack {
                Text("\(Int((snapshot.monthToDateUSD / max(monthlyBudgetUSD, 0.01)) * 100))% av budgeten")
                Spacer()
                if budgetLevel == 100 {
                    Label("Budget uppnådd", systemImage: "exclamationmark.octagon.fill")
                        .foregroundStyle(.red)
                } else if budgetLevel == 90 {
                    Label("90 % · nära taket", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                } else if budgetLevel == 75 {
                    Label("75 % · håll koll", systemImage: "exclamationmark.circle.fill")
                        .foregroundStyle(.yellow)
                } else {
                    Text("Under 75 %").foregroundStyle(StudioTheme.accentCyan)
                }
            }
            .font(.caption.weight(.medium)).foregroundStyle(StudioTheme.secondaryText)
            HStack {
                Text("Budget")
                    .font(.subheadline.weight(.medium)).foregroundStyle(StudioTheme.text)
                Spacer()
                Text(formattedCurrency(monthlyBudgetUSD, currency: "USD"))
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(StudioTheme.text)
            }
            Slider(value: $monthlyBudgetUSD, in: 1...500, step: 1)
                .tint(StudioTheme.accent)
            HStack(spacing: 10) {
                thresholdMarker("75 %", color: .yellow)
                thresholdMarker("90 %", color: .orange)
                thresholdMarker("100 %", color: .red)
            }
            Text("Budgetnivåerna markeras vid 75, 90 och 100 %. Budgeten är ett lokalt planeringsmål – den stoppar inte API-anrop.")
                .font(.caption2).foregroundStyle(StudioTheme.muted)
        }
    }

    private func thresholdMarker(_ title: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(title).font(.caption2.weight(.semibold)).foregroundStyle(StudioTheme.secondaryText)
        }
    }

    private func dailyChart(_ snapshot: OpenAICostSnapshot) -> some View {
        sectionCard(title: "Daglig förbrukning", subtitle: "USD per dag · aktuell månad") {
            if snapshot.daily.isEmpty {
                Text("Daglig statistik saknas i rapporten.")
                    .font(.subheadline).foregroundStyle(StudioTheme.secondaryText)
            } else {
                let maximumDailyCost = snapshot.daily.map(\.costUSD).max() ?? 0
                let chartUpperBound = max(maximumDailyCost * 1.25, 0.00001)
                Chart(snapshot.daily) { item in
                    BarMark(
                        x: .value("Datum", chartDate(item.date)),
                        y: .value("Kostnad", item.costUSD)
                    )
                    .foregroundStyle(StudioTheme.accent.gradient)
                    .cornerRadius(3)
                }
                .chartYScale(domain: 0...chartUpperBound)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { value in
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                            .foregroundStyle(StudioTheme.muted)
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine().foregroundStyle(StudioTheme.border)
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text(axisAmount(amount))
                                    .foregroundStyle(StudioTheme.muted)
                            }
                        }
                    }
                }
                .frame(height: 170)
            }
        }
    }

    private func projectSection(_ snapshot: OpenAICostSnapshot) -> some View {
        sectionCard(title: "Kostnad per projekt", subtitle: "Fördelning från OpenAI") {
            if snapshot.projects.isEmpty {
                Text("Ingen debiterad API-förbrukning per projekt ännu.")
                    .font(.subheadline).foregroundStyle(StudioTheme.secondaryText)
            } else {
                ForEach(snapshot.projects) { item in
                    costRow(projectLabel(item.projectID), value: item.costUSD, currency: snapshot.currency)
                }
            }
        }
    }

    private func lineItemSection(_ snapshot: OpenAICostSnapshot) -> some View {
        sectionCard(title: "Kostnadsposter", subtitle: "Modell och typ av tokenförbrukning") {
            if snapshot.lineItems.isEmpty {
                Text("Inga kostnadsposter ännu.")
                    .font(.subheadline).foregroundStyle(StudioTheme.secondaryText)
            } else {
                ForEach(snapshot.lineItems) { item in
                    costRow(item.name, value: item.costUSD, currency: snapshot.currency)
                }
            }
        }
    }

    private func updateMetadata(_ snapshot: OpenAICostSnapshot) -> some View {
        HStack(spacing: 7) {
            Image(systemName: "clock").foregroundStyle(StudioTheme.accentCyan)
            Text("Rapport uppdaterad \(formattedTimestamp(snapshot.updatedAt))")
            Spacer(minLength: 4)
            if let lastFetchAt {
                Text("Läst \(lastFetchAt.formatted(date: .omitted, time: .shortened))")
            }
        }
        .font(.caption2).foregroundStyle(StudioTheme.muted)
    }

    private func sectionCard<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline).foregroundStyle(StudioTheme.text)
                Text(subtitle).font(.caption).foregroundStyle(StudioTheme.muted)
            }
            content()
        }
        .padding(15).frame(maxWidth: .infinity, alignment: .leading)
        .background(StudioTheme.surface, in: RoundedRectangle(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(StudioTheme.border, lineWidth: 1))
    }

    private func costRow(_ title: String, value: Double, currency: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(title).font(.subheadline).foregroundStyle(StudioTheme.secondaryText)
                .lineLimit(2).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            Text(formattedCurrency(value, currency: currency))
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .foregroundStyle(StudioTheme.text)
        }
    }

    private func formattedCurrency(_ value: Double, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "sv_SE")
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.minimumFractionDigits = value > 0 && value < 0.01 ? 6 : 2
        formatter.maximumFractionDigits = 6
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    private func axisAmount(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "sv_SE")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 6
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    private func projectLabel(_ id: String) -> String {
        if id == "unassigned" { return "Ej kopplat till projekt" }
        return "Projekt-ID · …" + String(id.suffix(8))
    }

    private func chartDate(_ value: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: value) ?? .now
    }

    private func formattedTimestamp(_ value: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: value) else { return value }
        return date.formatted(date: .abbreviated, time: .shortened)
    }

    @MainActor
    private func loadSnapshot() async {
        guard !isLoading else { return }
        guard let token = GitHubTokenStore.read() else {
            errorMessage = "Spara först din GitHub-token i Assistent-fliken."
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            var request = URLRequest(url: URL(string: "https://api.github.com/repos/72cbbw422f-alt/devh/contents/data/openai-costs.json?ref=openai-metrics")!)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
            request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                throw URLError(.cannotParseResponse)
            }
            struct GitHubContent: Decodable { let content: String }
            let file = try JSONDecoder().decode(GitHubContent.self, from: data)
            let encoded = file.content.replacingOccurrences(of: "\n", with: "")
            guard let jsonData = Data(base64Encoded: encoded) else { throw URLError(.cannotDecodeContentData) }
            snapshot = try JSONDecoder().decode(OpenAICostSnapshot.self, from: jsonData)
            lastFetchAt = .now
            errorMessage = nil
        } catch {
            errorMessage = "Kunde inte läsa kostnadsrapporten. Kontrollera GitHub-tokenens behörighet och att rapporten har körts."
        }
    }
}
