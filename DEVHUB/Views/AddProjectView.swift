import SwiftUI

struct AddProjectView: View {
    @Environment(\.dismiss) private var dismiss
    let existingProject: StudioProject?
    let onSave: (StudioProject) -> Void

    init(project: StudioProject? = nil, onSave: @escaping (StudioProject) -> Void) {
        self.existingProject = project
        self.onSave = onSave
        _name = State(initialValue: project?.name ?? "")
        _subtitle = State(initialValue: project?.subtitle ?? "")
        _repository = State(initialValue: project.map { $0.repository.contains("/") ? $0.repository : "72cbbw422f-alt/\($0.repository)" } ?? "")
        _platform = State(initialValue: project?.platform ?? "iOS")
        _category = State(initialValue: project?.category ?? "App")
        _status = State(initialValue: project?.status ?? .planning)
        _accent = State(initialValue: project?.accent ?? "7164F2")
        _symbol = State(initialValue: project?.symbol ?? "app.fill")
    }

    @State private var name = ""
    @State private var subtitle = ""
    @State private var repository = ""
    @State private var platform = "iOS"
    @State private var category = "App"
    @State private var status: ProjectStatus = .planning
    @State private var accent = "7164F2"
    @State private var symbol = "app.fill"

    private let platforms = ["iOS", "iPadOS", "tvOS", "macOS", "Webb", "Annat"]
    private let categories = ["App", "Produktivitet", "Underhållning", "Väder", "Smarta hemmet", "Verktyg", "Annat"]
    private let accents = ["7164F2", "398BFF", "45C6D9", "568AE8", "E59A55", "46B887"]

    private var normalizedRepository: String {
        var value = repository.trimmingCharacters(in: .whitespacesAndNewlines)
        value = value.replacingOccurrences(of: "https://github.com/", with: "")
        value = value.replacingOccurrences(of: "http://github.com/", with: "")
        if value.hasSuffix(".git") { value.removeLast(4) }
        return value.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (normalizedRepository.isEmpty || normalizedRepository.split(separator: "/").count == 2)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Grundinformation") {
                    TextField("Projektnamn", text: $name)
                    TextField("Kort beskrivning", text: $subtitle, axis: .vertical)
                        .lineLimit(2...4)
                    Picker("Plattform", selection: $platform) {
                        ForEach(platforms, id: \.self) { Text($0) }
                    }
                    Picker("Kategori", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0) }
                    }
                }
                Section("GitHub") {
                    TextField("ägare/repository eller GitHub-länk", text: $repository)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    Text("Valfritt. Ange exempelvis användare/projektnamn eller hela GitHub-adressen.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("Utseende och status") {
                    Picker("Status", selection: $status) {
                        ForEach(ProjectStatus.allCases) { Text($0.rawValue).tag($0) }
                    }
                    HStack {
                        ForEach(accents, id: \.self) { color in
                            Circle().fill(Color(hex: color)).frame(width: 30, height: 30)
                                .overlay(Circle().stroke(.white.opacity(accent == color ? 0.9 : 0), lineWidth: 2).padding(-4))
                                .onTapGesture { accent = color }
                                .accessibilityLabel("Välj projektfärg")
                        }
                    }.padding(.vertical, 6)
                }
            }
            .scrollContentBackground(.hidden)
            .background(StudioTheme.background)
            .navigationTitle(existingProject == nil ? "Nytt projekt" : "Redigera projekt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existingProject == nil ? "Lägg till" : "Spara") { save() }.disabled(!isValid)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func save() {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanSubtitle = subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let repo = normalizedRepository
        let project = StudioProject(
            id: existingProject?.id ?? "custom-\(UUID().uuidString)",
            name: cleanName,
            subtitle: cleanSubtitle.isEmpty ? "Nytt projekt i DEVHUB." : cleanSubtitle,
            platform: platform,
            category: category,
            repository: repo,
            progress: existingProject?.progress ?? 0,
            status: status,
            symbol: symbol,
            accent: accent,
            nextMilestone: existingProject?.nextMilestone ?? "Definiera projektets första milstolpe"
        )
        onSave(project)
        dismiss()
    }
}
