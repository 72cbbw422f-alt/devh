import SwiftUI
import SwiftData

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
                Text(project.platform + " · " + project.category).lineLimit(1)
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
                        .fill(LinearGradient(colors: [Color(hex: project.accent), StudioTheme.accent], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(5, proxy.size.width * min(max(project.progress, 0), 1)))
                }
            }
            .frame(height: 5)
            HStack(spacing: 5) {
                Image(systemName: "arrow.up.right.square")
                Text(project.repository).lineLimit(1)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 8, weight: .bold))
            }
            .font(.system(size: 9, design: .monospaced))
            .foregroundStyle(StudioTheme.muted)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(colors: [StudioTheme.surface, StudioTheme.surface.opacity(0.82)], startPoint: .topLeading, endPoint: .bottomTrailing))
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
    let onSelect: (StudioProject) -> Void
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StudioProjectRecord.createdAt) private var records: [StudioProjectRecord]
    @State private var showArchived = false
    @State private var editingRecord: StudioProjectRecord?
    @State private var showingEditor = false

    private var visibleRecords: [StudioProjectRecord] {
        records.filter { $0.isArchived == showArchived }
    }

    var body: some View {
        List {
            ForEach(visibleRecords) { record in
                Button { onSelect(record.project) } label: {
                    HStack(spacing: 12) {
                        Image(systemName: record.symbol)
                            .foregroundStyle(Color(hex: record.accent))
                            .frame(width: 40, height: 40)
                            .background(StudioTheme.elevated, in: RoundedRectangle(cornerRadius: 12))
                        VStack(alignment: .leading, spacing: 5) {
                            Text(record.name).font(.headline).foregroundStyle(StudioTheme.text)
                            Text(record.repository.isEmpty ? record.platform : record.repository)
                                .font(.caption).foregroundStyle(StudioTheme.muted)
                            ProgressView(value: record.progress).tint(Color(hex: record.accent))
                        }
                        Spacer()
                        Text("\(Int(record.progress * 100))%")
                            .font(.caption.monospacedDigit().weight(.semibold))
                            .foregroundStyle(StudioTheme.accent)
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(StudioTheme.surface)
                .listRowSeparatorTint(StudioTheme.border)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button {
                        record.isArchived.toggle()
                    } label: {
                        Label(record.isArchived ? "Återställ" : "Arkivera",
                              systemImage: record.isArchived ? "tray.and.arrow.up" : "archivebox")
                    }
                    .tint(record.isArchived ? .green : .orange)
                    Button {
                        editingRecord = record
                        showingEditor = true
                    } label: {
                        Label("Redigera", systemImage: "pencil")
                    }
                    .tint(.indigo)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(StudioTheme.background)
        .navigationTitle(showArchived ? "Arkiverade projekt" : "Projekt")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showArchived.toggle()
                } label: {
                    Image(systemName: showArchived ? "tray.full" : "archivebox")
                }
                .accessibilityLabel(showArchived ? "Visa aktiva projekt" : "Visa arkiverade projekt")
            }
        }
        .sheet(isPresented: $showingEditor, onDismiss: { editingRecord = nil }) {
            if let record = editingRecord {
                AddProjectView(project: record.project) { updated in
                    record.name = updated.name
                    record.subtitle = updated.subtitle
                    record.platform = updated.platform
                    record.category = updated.category
                    record.repository = updated.repository
                    record.statusRawValue = updated.status.rawValue
                    record.symbol = updated.symbol
                    record.accent = updated.accent
                    record.nextMilestone = updated.nextMilestone
                }
            }
        }
    }
}
