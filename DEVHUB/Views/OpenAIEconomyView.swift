import SwiftUI

struct OpenAIEconomyView: View {
    @State private var snapshot: OpenAICostSnapshot?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var lastUpdated: String?

    private let billingURL = URL(string: "https://platform.openai.com/settings/organization/billing/overview")!

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 5) {
                    Label("OPENAI · API-KOSTNADER", systemImage: "chart.xyaxis.line")
                        .font(.caption.bold()).foregroundStyle(StudioTheme.accent)
                    Text("AI-ekonomi")
                        .font(.system(size: 29, weight: .bold, design: .rounded))
                        .foregroundStyle(StudioTheme.text)
                    Text("Förbrukning och kostnader för din OpenAI-organisation.")
                        .font(.subheadline).foregroundStyle(StudioTheme.secondaryText)
                }

                if let snapshot {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("Förbrukning denna månad").font(.caption).foregroundStyle(StudioTheme.secondaryText)
                        Text(snapshot.monthToDateUSD, format: .currency(code: "USD"))
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(StudioTheme.text)
                        Text("Sedan \(snapshot.monthStart)")
                            .font(.caption).foregroundStyle(StudioTheme.muted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(StudioTheme.surface, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(StudioTheme.border, lineWidth: 1))

                    sectionCard(title: "Kostnad per projekt", subtitle: "Hämtat från OpenAI") {
                        if snapshot.projects.isEmpty {
                            Text("Ingen debiterad API-förbrukning registrerad denna månad.")
                                .font(.subheadline).foregroundStyle(StudioTheme.secondaryText)
                        } else {
                            ForEach(snapshot.projects) { item in
                                costRow(item.projectID, value: item.costUSD)
                            }
                        }
                    }

                    sectionCard(title: "Kostnadsposter", subtitle: "Fördelning enligt OpenAI") {
                        if snapshot.lineItems.isEmpty {
                            Text("Inga kostnadsposter ännu.")
                                .font(.subheadline).foregroundStyle(StudioTheme.secondaryText)
                        } else {
                            ForEach(snapshot.lineItems) { item in
                                costRow(item.name, value: item.costUSD)
                            }
                        }
                    }

                    if !snapshot.daily.isEmpty {
                        sectionCard(title: "Daglig förbrukning", subtitle: "USD per dag") {
                            ForEach(snapshot.daily.suffix(10)) { item in
                                costRow(item.date, value: item.costUSD)
                            }
                        }
                    }
                    Text("Senast uppdaterad: \(snapshot.updatedAt)")
                        .font(.caption2).foregroundStyle(StudioTheme.muted)
                } else if isLoading {
                    ProgressView("Hämtar OpenAI-kostnader…")
                        .frame(maxWidth: .infinity).padding(30)
                } else {
                    sectionCard(title: "Ingen kostnadsdata ännu", subtitle: "Anslut OpenAI för att börja") {
                        Text(errorMessage ?? "När administratörsnyckeln är konfigurerad visas kostnader här.")
                            .font(.subheadline).foregroundStyle(StudioTheme.secondaryText)
                    }
                }

                sectionCard(title: "Kreditsaldo", subtitle: "Hanteras separat av OpenAI") {
                    Text("OpenAI erbjuder ingen publik API-endpoint för att läsa återstående förbetalda krediter. Därför visar vi inte ett uppskattat saldo här.")
                        .font(.subheadline).foregroundStyle(StudioTheme.secondaryText)
                    Link(destination: billingURL) {
                        Label("Öppna OpenAI Billing", systemImage: "arrow.up.right.square")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(StudioTheme.accent)
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
            }
            .padding(18)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(StudioTheme.background.ignoresSafeArea())
        .navigationTitle("Ekonomi")
        .task { await loadSnapshot() }
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

    private func costRow(_ title: String, value: Double) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.subheadline).foregroundStyle(StudioTheme.secondaryText).lineLimit(2)
            Spacer(minLength: 12)
            Text(value, format: .currency(code: "USD"))
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .foregroundStyle(StudioTheme.text)
        }
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
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                throw URLError(.cannotParseResponse)
            }
            struct GitHubContent: Decodable { let content: String }
            let file = try JSONDecoder().decode(GitHubContent.self, from: data)
            let encoded = file.content.replacingOccurrences(of: "\n", with: "")
            guard let jsonData = Data(base64Encoded: encoded) else { throw URLError(.cannotDecodeContentData) }
            snapshot = try JSONDecoder().decode(OpenAICostSnapshot.self, from: jsonData)
            errorMessage = nil
        } catch {
            errorMessage = "Kunde inte läsa kostnadsrapporten. Kontrollera GitHub-tokenens behörighet och att OpenAI-rapporten har körts."
        }
    }
}
