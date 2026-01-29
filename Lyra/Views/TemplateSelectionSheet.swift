import SwiftUI
import SwiftData

struct TemplateSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Template.name) private var templates: [Template]

    let onSelect: (Template) -> Void

    @State private var searchText: String = ""
    @State private var selectedCategory: TemplateCategory = .all
    @State private var showingTemplateEditor: Bool = false
    @State private var selectedTemplate: Template?

    private var filteredTemplates: [Template] {
        var filtered = templates

        // Filter by category
        switch selectedCategory {
        case .all:
            break
        case .builtIn:
            filtered = filtered.filter { $0.isBuiltIn }
        case .custom:
            filtered = filtered.filter { !$0.isBuiltIn }
        }

        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { template in
                template.name.localizedCaseInsensitiveContains(searchText)
            }
        }

        return filtered
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                searchBar

                // Category Picker
                categoryPicker

                // Template List
                if filteredTemplates.isEmpty {
                    emptyStateView
                } else {
                    templateList
                }
            }
            .navigationTitle("Select Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticManager.shared.selection()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        createNewTemplate()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $selectedTemplate) { template in
                TemplateEditorView(template: template)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Subviews

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search templates", text: $searchText)
                .textFieldStyle(.plain)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    HapticManager.shared.selection()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var categoryPicker: some View {
        Picker("Category", selection: $selectedCategory) {
            ForEach(TemplateCategory.allCases) { category in
                Text(category.rawValue).tag(category)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.bottom, 8)
        .onChange(of: selectedCategory) { _, _ in
            HapticManager.shared.selection()
        }
    }

    private var templateList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredTemplates) { template in
                    TemplateRow(template: template) {
                        selectTemplate(template)
                    } onInfo: {
                        viewTemplateDetails(template)
                    }
                }
            }
            .padding()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Templates Found")
                .font(.headline)

            if !searchText.isEmpty {
                Text("Try adjusting your search or filters")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Create your first custom template")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    createNewTemplate()
                } label: {
                    Label("Create Template", systemImage: "plus.circle.fill")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Actions

    private func selectTemplate(_ template: Template) {
        HapticManager.shared.selection()
        onSelect(template)
        dismiss()
    }

    private func viewTemplateDetails(_ template: Template) {
        HapticManager.shared.selection()
        selectedTemplate = template
    }

    private func createNewTemplate() {
        HapticManager.shared.selection()
        do {
            let newTemplate = try TemplateManager.createTemplate(
                name: "New Template",
                context: modelContext
            )
            selectedTemplate = newTemplate
        } catch {
            print("❌ Error creating template: \(error.localizedDescription)")
        }
    }
}

// MARK: - Template Row

struct TemplateRow: View {
    let template: Template
    let onSelect: () -> Void
    let onInfo: () -> Void

    var body: some View {
        Button {
            onSelect()
        } label: {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundStyle(template.isBuiltIn ? .blue : .purple)
                    .frame(width: 40)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(template.name)
                            .font(.headline)

                        if template.isDefault {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                        }
                    }

                    Text(templateDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                // Info Button
                Button {
                    onInfo()
                } label: {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }

    private var iconName: String {
        if template.isBuiltIn {
            return "doc.text.fill"
        } else {
            return "doc.badge.gearshape"
        }
    }

    private var templateDescription: String {
        var parts: [String] = []

        // Column count
        if template.columnCount == 1 {
            parts.append("Single column")
        } else {
            parts.append("\(template.columnCount) columns")
        }

        // Balancing strategy
        switch template.columnBalancingStrategy {
        case .fillFirst:
            parts.append("Fill first")
        case .balanced:
            parts.append("Balanced")
        case .sectionBased:
            parts.append("Section based")
        }

        // Chord positioning
        switch template.chordPositioningStyle {
        case .chordsOverLyrics:
            parts.append("Chords over lyrics")
        case .inline:
            parts.append("Inline chords")
        case .separateLines:
            parts.append("Separate chord lines")
        }

        return parts.joined(separator: " • ")
    }
}

// MARK: - Template Category

enum TemplateCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case builtIn = "Built-in"
    case custom = "Custom"

    var id: String { rawValue }
}

// MARK: - Preview

#Preview("Template Selection") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Template.self, configurations: config)

    // Create sample templates
    let builtIn1 = Template.builtInSingleColumn()
    let builtIn2 = Template.builtInTwoColumn()
    let builtIn3 = Template.builtInThreeColumn()

    let custom1 = Template(name: "My Custom Template")
    custom1.columnCount = 2
    custom1.columnGap = 16
    custom1.chordPositioningStyle = .inline

    let custom2 = Template(name: "Performance Layout")
    custom2.columnCount = 3
    custom2.columnGap = 20
    custom2.chordPositioningStyle = .separateLines
    custom2.isDefault = true

    container.mainContext.insert(builtIn1)
    container.mainContext.insert(builtIn2)
    container.mainContext.insert(builtIn3)
    container.mainContext.insert(custom1)
    container.mainContext.insert(custom2)

    return TemplateSelectionSheet { template in
        print("Selected: \(template.name)")
    }
    .modelContainer(container)
}

#Preview("Empty State") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Template.self, configurations: config)

    return TemplateSelectionSheet { template in
        print("Selected: \(template.name)")
    }
    .modelContainer(container)
}
