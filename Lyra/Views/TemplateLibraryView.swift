import SwiftUI
import SwiftData

struct TemplateLibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Template.name) private var templates: [Template]

    @State private var searchText: String = ""
    @State private var selectedCategory: TemplateLibraryCategory = .all
    @State private var showAddTemplateSheet: Bool = false
    @State private var showImportTemplateSheet: Bool = false
    @State private var selectedTemplate: Template?
    @State private var showDeleteConfirmation: Bool = false
    @State private var templateToDelete: Template?
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    @State private var errorRecoverySuggestion: String = ""

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
            .navigationTitle("Templates")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            createNewTemplate()
                        } label: {
                            Label("New Template", systemImage: "doc.badge.plus")
                        }

                        Divider()

                        Button {
                            showImportTemplateSheet = true
                        } label: {
                            Label("Import from PDF", systemImage: "doc.viewfinder")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add template")
                }
            }
            .sheet(item: $selectedTemplate) { template in
                TemplateEditorView(template: template)
            }
            .sheet(isPresented: $showImportTemplateSheet) {
                TemplateImportView()
            }
            .alert("Delete Template", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    templateToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let template = templateToDelete {
                        deleteTemplate(template)
                    }
                }
            } message: {
                if let template = templateToDelete {
                    Text("Are you sure you want to delete \"\(template.name)\"? This action cannot be undone.")
                }
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                VStack {
                    Text(errorMessage)
                    if !errorRecoverySuggestion.isEmpty {
                        Text(errorRecoverySuggestion)
                    }
                }
            }
        }
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
            ForEach(TemplateLibraryCategory.allCases) { category in
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
                    TemplateLibraryRow(template: template) {
                        viewTemplateDetails(template)
                    } onDuplicate: {
                        duplicateTemplate(template)
                    } onDelete: {
                        confirmDeleteTemplate(template)
                    } onSetDefault: {
                        setDefaultTemplate(template)
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
            showError(
                message: "Failed to create template",
                recovery: error.localizedDescription
            )
        }
    }

    private func duplicateTemplate(_ template: Template) {
        HapticManager.shared.selection()
        do {
            let duplicateName = "\(template.name) Copy"
            let duplicate = try TemplateManager.duplicateTemplate(
                template,
                newName: duplicateName,
                context: modelContext
            )
            HapticManager.shared.success()
            selectedTemplate = duplicate
        } catch {
            HapticManager.shared.operationFailed()
            showError(
                message: "Failed to duplicate template",
                recovery: error.localizedDescription
            )
        }
    }

    private func confirmDeleteTemplate(_ template: Template) {
        HapticManager.shared.selection()
        templateToDelete = template
        showDeleteConfirmation = true
    }

    private func deleteTemplate(_ template: Template) {
        do {
            try TemplateManager.deleteTemplate(template, context: modelContext)
            HapticManager.shared.success()
            templateToDelete = nil
        } catch {
            HapticManager.shared.operationFailed()
            showError(
                message: "Failed to delete template",
                recovery: error.localizedDescription
            )
            templateToDelete = nil
        }
    }

    private func setDefaultTemplate(_ template: Template) {
        HapticManager.shared.selection()
        do {
            try TemplateManager.setDefaultTemplate(template, context: modelContext)
            HapticManager.shared.success()
        } catch {
            HapticManager.shared.operationFailed()
            showError(
                message: "Failed to set default template",
                recovery: error.localizedDescription
            )
        }
    }

    private func showError(message: String, recovery: String) {
        errorMessage = message
        errorRecoverySuggestion = recovery
        showErrorAlert = true
    }
}

// MARK: - Template Library Row

struct TemplateLibraryRow: View {
    let template: Template
    let onTap: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void
    let onSetDefault: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(spacing: 0) {
                // Main Content
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

                    // Chevron
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(16)
                .contentShape(Rectangle())
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            .contextMenu {
                Button {
                    onTap()
                } label: {
                    Label("View Details", systemImage: "eye")
                }

                if !template.isDefault {
                    Button {
                        onSetDefault()
                    } label: {
                        Label("Set as Default", systemImage: "star")
                    }
                }

                Button {
                    onDuplicate()
                } label: {
                    Label("Duplicate", systemImage: "doc.on.doc")
                }

                if !template.isBuiltIn {
                    Divider()

                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
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

// MARK: - Template Library Category

enum TemplateLibraryCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case builtIn = "Built-in"
    case custom = "Custom"

    var id: String { rawValue }
}

// MARK: - Preview

#Preview("Template Library") {
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

    let custom3 = Template(name: "Compact View")
    custom3.columnCount = 1
    custom3.bodyFontSize = 14
    custom3.chordFontSize = 12

    container.mainContext.insert(builtIn1)
    container.mainContext.insert(builtIn2)
    container.mainContext.insert(builtIn3)
    container.mainContext.insert(custom1)
    container.mainContext.insert(custom2)
    container.mainContext.insert(custom3)

    return TemplateLibraryView()
        .modelContainer(container)
}

#Preview("Empty State") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Template.self, configurations: config)

    return TemplateLibraryView()
        .modelContainer(container)
}
