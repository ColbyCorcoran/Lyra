import SwiftUI
import SwiftData

struct TemplateEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let template: Template

    @State private var name: String
    @State private var columnCount: Int
    @State private var columnGap: Double
    @State private var columnWidthMode: ColumnWidthMode
    @State private var columnBalancingStrategy: ColumnBalancingStrategy
    @State private var customColumnWidths: [Double]
    @State private var chordPositioningStyle: ChordPositioningStyle
    @State private var chordAlignment: ChordAlignment
    @State private var titleFontSize: Double
    @State private var headingFontSize: Double
    @State private var bodyFontSize: Double
    @State private var chordFontSize: Double
    @State private var sectionBreakBehavior: SectionBreakBehavior

    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    @State private var hasChanges: Bool = false

    private var isBuiltIn: Bool {
        template.isBuiltIn
    }

    private var canSave: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty && hasChanges && !isBuiltIn
    }

    init(template: Template) {
        self.template = template
        _name = State(initialValue: template.name)
        _columnCount = State(initialValue: template.columnCount)
        _columnGap = State(initialValue: template.columnGap)
        _columnWidthMode = State(initialValue: template.columnWidthMode)
        _columnBalancingStrategy = State(initialValue: template.columnBalancingStrategy)
        _customColumnWidths = State(initialValue: template.customColumnWidths ?? [])
        _chordPositioningStyle = State(initialValue: template.chordPositioningStyle)
        _chordAlignment = State(initialValue: template.chordAlignment)
        _titleFontSize = State(initialValue: template.titleFontSize)
        _headingFontSize = State(initialValue: template.headingFontSize)
        _bodyFontSize = State(initialValue: template.bodyFontSize)
        _chordFontSize = State(initialValue: template.chordFontSize)
        _sectionBreakBehavior = State(initialValue: template.sectionBreakBehavior)
    }

    var body: some View {
        NavigationStack {
            Form {
                if isBuiltIn {
                    Section {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.blue)
                            Text("This is a built-in template and cannot be edited. You can duplicate it to create a custom version.")
                                .font(.callout)
                        }
                    }
                }

                basicInfoSection

                columnConfigurationSection

                chordPositioningSection

                typographySection

                layoutRulesSection

                if !isBuiltIn {
                    actionsSection
                }
            }
            .navigationTitle(isBuiltIn ? "View Template" : "Edit Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticManager.shared.selection()
                        dismiss()
                    }
                }

                if !isBuiltIn {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            saveChanges()
                        }
                        .disabled(!canSave)
                    }
                }
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Sections

    private var basicInfoSection: some View {
        Section {
            HStack {
                Text("Name")
                Spacer()
                TextField("Template name", text: $name)
                    .multilineTextAlignment(.trailing)
                    .disabled(isBuiltIn)
                    .onChange(of: name) { _, _ in hasChanges = true }
            }
        } header: {
            Text("Basic Info")
        } footer: {
            Text("Give your template a descriptive name.")
        }
    }

    private var columnConfigurationSection: some View {
        Section {
            Picker("Column Count", selection: $columnCount) {
                ForEach(1...4, id: \.self) { count in
                    Text("\(count)").tag(count)
                }
            }
            .disabled(isBuiltIn)
            .onChange(of: columnCount) { oldValue, newValue in
                hasChanges = true
                // Adjust custom widths array if needed
                if columnWidthMode == .custom {
                    adjustCustomColumnWidths(for: newValue)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Column Gap")
                    Spacer()
                    Text("\(Int(columnGap)) pt")
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
                Slider(value: $columnGap, in: 0...40, step: 2)
                    .disabled(isBuiltIn)
                    .onChange(of: columnGap) { _, _ in hasChanges = true }
            }

            Picker("Width Mode", selection: $columnWidthMode) {
                Text("Equal").tag(ColumnWidthMode.equal)
                Text("Custom").tag(ColumnWidthMode.custom)
            }
            .disabled(isBuiltIn)
            .onChange(of: columnWidthMode) { _, newValue in
                hasChanges = true
                if newValue == .custom && customColumnWidths.isEmpty {
                    adjustCustomColumnWidths(for: columnCount)
                }
            }

            if columnWidthMode == .custom {
                customColumnWidthsEditor
            }

            Picker("Balancing Strategy", selection: $columnBalancingStrategy) {
                Text("Fill First").tag(ColumnBalancingStrategy.fillFirst)
                Text("Balanced").tag(ColumnBalancingStrategy.balanced)
                Text("Section Based").tag(ColumnBalancingStrategy.sectionBased)
            }
            .disabled(isBuiltIn)
            .onChange(of: columnBalancingStrategy) { _, _ in hasChanges = true }

        } header: {
            Text("Column Configuration")
        } footer: {
            Text(columnConfigurationFooter)
        }
    }

    private var customColumnWidthsEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Custom Column Widths")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(0..<columnCount, id: \.self) { index in
                if index < customColumnWidths.count {
                    HStack {
                        Text("Column \(index + 1)")
                        Spacer()
                        Stepper("\(String(format: "%.1f", customColumnWidths[index]))", value: Binding(
                            get: { customColumnWidths[index] },
                            set: { newValue in
                                customColumnWidths[index] = newValue
                                hasChanges = true
                            }
                        ), in: 0.5...3.0, step: 0.1)
                        .disabled(isBuiltIn)
                    }
                }
            }

            Text("Relative widths (1.0 = standard width)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var chordPositioningSection: some View {
        Section {
            Picker("Positioning Style", selection: $chordPositioningStyle) {
                Text("Chords Over Lyrics").tag(ChordPositioningStyle.chordsOverLyrics)
                Text("Inline").tag(ChordPositioningStyle.inline)
                Text("Separate Lines").tag(ChordPositioningStyle.separateLines)
            }
            .disabled(isBuiltIn)
            .onChange(of: chordPositioningStyle) { _, _ in hasChanges = true }

            Picker("Alignment", selection: $chordAlignment) {
                Text("Left").tag(ChordAlignment.leftAligned)
                Text("Centered").tag(ChordAlignment.centered)
                Text("Right").tag(ChordAlignment.rightAligned)
            }
            .disabled(isBuiltIn)
            .onChange(of: chordAlignment) { _, _ in hasChanges = true }

        } header: {
            Text("Chord Positioning")
        } footer: {
            Text("Configure how chords are displayed relative to lyrics.")
        }
    }

    private var typographySection: some View {
        Section {
            fontSizeSlider(
                label: "Title Font",
                value: $titleFontSize,
                range: 18...48
            )

            fontSizeSlider(
                label: "Heading Font",
                value: $headingFontSize,
                range: 12...32
            )

            fontSizeSlider(
                label: "Body Font",
                value: $bodyFontSize,
                range: 10...24
            )

            fontSizeSlider(
                label: "Chord Font",
                value: $chordFontSize,
                range: 8...20
            )

        } header: {
            Text("Typography")
        } footer: {
            Text("Set the font sizes for different text elements.")
        }
    }

    private var layoutRulesSection: some View {
        Section {
            Picker("Section Break Behavior", selection: $sectionBreakBehavior) {
                Text("Continue in Column").tag(SectionBreakBehavior.continueInColumn)
                Text("New Column").tag(SectionBreakBehavior.newColumn)
                Text("Space Before").tag(SectionBreakBehavior.spaceBefore)
            }
            .disabled(isBuiltIn)
            .onChange(of: sectionBreakBehavior) { _, _ in hasChanges = true }

        } header: {
            Text("Layout Rules")
        } footer: {
            Text("Control how section breaks affect the layout.")
        }
    }

    private var actionsSection: some View {
        Section {
            Button {
                setAsDefault()
            } label: {
                HStack {
                    Image(systemName: template.isDefault ? "star.fill" : "star")
                    Text(template.isDefault ? "Default Template" : "Set as Default")
                }
                .foregroundStyle(template.isDefault ? .secondary : .primary)
            }
            .disabled(template.isDefault)

            Button {
                duplicateTemplate()
            } label: {
                HStack {
                    Image(systemName: "doc.on.doc")
                    Text("Duplicate Template")
                }
            }

            Button(role: .destructive) {
                deleteTemplate()
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Template")
                }
            }

        } header: {
            Text("Actions")
        }
    }

    // MARK: - Helper Views

    private func fontSizeSlider(label: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(label)
                Spacer()
                Text("\(Int(value.wrappedValue)) pt")
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range, step: 1)
                .disabled(isBuiltIn)
                .onChange(of: value.wrappedValue) { _, _ in hasChanges = true }
        }
    }

    // MARK: - Computed Properties

    private var columnConfigurationFooter: String {
        switch columnBalancingStrategy {
        case .fillFirst:
            return "Fill first column completely before moving to the next."
        case .balanced:
            return "Distribute content evenly across all columns."
        case .sectionBased:
            return "Keep song sections together in the same column when possible."
        }
    }

    // MARK: - Actions

    private func saveChanges() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter a template name."
            showErrorAlert = true
            HapticManager.shared.operationFailed()
            return
        }

        // Validate name uniqueness if changed
        if trimmedName != template.name {
            do {
                let isValid = try TemplateManager.isValidTemplateName(
                    trimmedName,
                    excludingTemplate: template,
                    in: modelContext
                )

                if !isValid {
                    errorMessage = "A template with this name already exists."
                    showErrorAlert = true
                    HapticManager.shared.operationFailed()
                    return
                }
            } catch {
                errorMessage = "Unable to validate template name: \(error.localizedDescription)"
                showErrorAlert = true
                HapticManager.shared.operationFailed()
                return
            }
        }

        // Apply changes
        template.name = trimmedName
        template.columnCount = columnCount
        template.columnGap = columnGap
        template.columnWidthMode = columnWidthMode
        template.columnBalancingStrategy = columnBalancingStrategy
        template.customColumnWidths = columnWidthMode == .custom ? customColumnWidths : nil
        template.chordPositioningStyle = chordPositioningStyle
        template.chordAlignment = chordAlignment
        template.titleFontSize = titleFontSize
        template.headingFontSize = headingFontSize
        template.bodyFontSize = bodyFontSize
        template.chordFontSize = chordFontSize
        template.sectionBreakBehavior = sectionBreakBehavior
        template.modifiedAt = Date()

        // Validate template
        guard template.isValid else {
            errorMessage = "Template configuration is invalid. Please check all settings."
            showErrorAlert = true
            HapticManager.shared.operationFailed()
            return
        }

        do {
            try modelContext.save()
            HapticManager.shared.saveSuccess()
            dismiss()
        } catch {
            print("❌ Error saving template: \(error.localizedDescription)")
            errorMessage = "Unable to save template. Please try again."
            showErrorAlert = true
            HapticManager.shared.operationFailed()
        }
    }

    private func setAsDefault() {
        do {
            try TemplateManager.setDefaultTemplate(template, context: modelContext)
            HapticManager.shared.saveSuccess()
            hasChanges = false
        } catch {
            print("❌ Error setting default template: \(error.localizedDescription)")
            errorMessage = "Unable to set as default template."
            showErrorAlert = true
            HapticManager.shared.operationFailed()
        }
    }

    private func duplicateTemplate() {
        do {
            let duplicateName = "\(template.name) Copy"
            _ = try TemplateManager.duplicateTemplate(template, newName: duplicateName, context: modelContext)
            HapticManager.shared.saveSuccess()
            dismiss()
        } catch {
            print("❌ Error duplicating template: \(error.localizedDescription)")
            errorMessage = "Unable to duplicate template: \(error.localizedDescription)"
            showErrorAlert = true
            HapticManager.shared.operationFailed()
        }
    }

    private func deleteTemplate() {
        do {
            try TemplateManager.deleteTemplate(template, context: modelContext)
            HapticManager.shared.medium()
            dismiss()
        } catch {
            print("❌ Error deleting template: \(error.localizedDescription)")
            errorMessage = "Unable to delete template: \(error.localizedDescription)"
            showErrorAlert = true
            HapticManager.shared.operationFailed()
        }
    }

    private func adjustCustomColumnWidths(for count: Int) {
        if customColumnWidths.count < count {
            // Add more widths with default value of 1.0
            customColumnWidths.append(contentsOf: Array(repeating: 1.0, count: count - customColumnWidths.count))
        } else if customColumnWidths.count > count {
            // Remove excess widths
            customColumnWidths = Array(customColumnWidths.prefix(count))
        }
    }
}

// MARK: - Preview

#Preview("Edit Template") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Template.self, configurations: config)

    let template = Template(name: "Custom Layout")
    template.columnCount = 2
    template.columnGap = 16
    template.columnWidthMode = .equal
    template.columnBalancingStrategy = .balanced
    template.chordPositioningStyle = .chordsOverLyrics
    template.chordAlignment = .leftAligned
    template.titleFontSize = 24
    template.headingFontSize = 18
    template.bodyFontSize = 14
    template.chordFontSize = 12
    template.sectionBreakBehavior = .spaceBefore
    container.mainContext.insert(template)

    return TemplateEditorView(template: template)
        .modelContainer(container)
}

#Preview("Built-in Template") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Template.self, configurations: config)

    let template = Template(name: "Single Column")
    template.isBuiltIn = true
    template.columnCount = 1
    template.columnGap = 0
    template.columnWidthMode = .equal
    template.columnBalancingStrategy = .fillFirst
    template.chordPositioningStyle = .chordsOverLyrics
    template.chordAlignment = .leftAligned
    template.titleFontSize = 24
    template.headingFontSize = 18
    template.bodyFontSize = 14
    template.chordFontSize = 12
    template.sectionBreakBehavior = .spaceBefore
    container.mainContext.insert(template)

    return TemplateEditorView(template: template)
        .modelContainer(container)
}
