//
//  RecurrenceRuleBuilderView.swift
//  Lyra
//
//  Created by Claude on 1/28/26.
//

import SwiftUI
import SwiftData

struct RecurrenceRuleBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Binding var recurrenceRule: RecurrenceRule?

    @State private var isRecurring: Bool = false
    @State private var frequency: RecurrenceFrequency = .weekly
    @State private var interval: Int = 1
    @State private var selectedDaysOfWeek: Set<DayOfWeek> = []
    @State private var dayOfMonth: Int = 1
    @State private var monthOfYear: Int = 1
    @State private var isMonthYearOnly: Bool = false
    @State private var endType: RecurrenceEndType = .never
    @State private var endDate: Date = Date()
    @State private var endAfterOccurrences: Int = 10

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Enable Recurrence", isOn: $isRecurring)
                } footer: {
                    if isRecurring {
                        Text("This set will automatically create recurring instances")
                    }
                }

                if isRecurring {
                    frequencySection
                    patternSection
                    endConditionSection
                    previewSection
                }
            }
            .navigationTitle("Recurrence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRecurrenceRule()
                    }
                }
            }
            .onAppear {
                loadExistingRule()
            }
        }
    }

    // MARK: - Sections

    private var frequencySection: some View {
        Section {
            Picker("Repeat", selection: $frequency) {
                Text("Daily").tag(RecurrenceFrequency.daily)
                Text("Weekly").tag(RecurrenceFrequency.weekly)
                Text("Monthly").tag(RecurrenceFrequency.monthly)
                Text("Yearly").tag(RecurrenceFrequency.yearly)
            }
            .pickerStyle(.segmented)

            Stepper("Every \(interval) \(frequencyUnit)", value: $interval, in: 1...99)
        } header: {
            Text("Frequency")
        }
    }

    private var patternSection: some View {
        Section {
            switch frequency {
            case .daily:
                Text("Repeats every \(interval) day(s)")
                    .foregroundStyle(.secondary)

            case .weekly:
                VStack(alignment: .leading, spacing: 12) {
                    Text("Repeat on:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 8) {
                        ForEach(DayOfWeek.allCases, id: \.rawValue) { day in
                            DayButton(
                                day: day,
                                isSelected: selectedDaysOfWeek.contains(day),
                                action: {
                                    if selectedDaysOfWeek.contains(day) {
                                        selectedDaysOfWeek.remove(day)
                                    } else {
                                        selectedDaysOfWeek.insert(day)
                                    }
                                }
                            )
                        }
                    }
                }
                .padding(.vertical, 8)

            case .monthly:
                Toggle("Month/Year Only (no specific day)", isOn: $isMonthYearOnly)

                if !isMonthYearOnly {
                    Picker("Day of Month", selection: $dayOfMonth) {
                        ForEach(1...31, id: \.self) { day in
                            Text("\(day)").tag(day)
                        }
                    }
                }

            case .yearly:
                Picker("Month", selection: $monthOfYear) {
                    ForEach(1...12, id: \.self) { month in
                        Text(Calendar.current.monthSymbols[month - 1]).tag(month)
                    }
                }

                Toggle("Month/Year Only (no specific day)", isOn: $isMonthYearOnly)

                if !isMonthYearOnly {
                    Picker("Day of Month", selection: $dayOfMonth) {
                        ForEach(1...31, id: \.self) { day in
                            Text("\(day)").tag(day)
                        }
                    }
                }
            }
        } header: {
            Text("Pattern")
        }
    }

    private var endConditionSection: some View {
        Section {
            Picker("Ends", selection: $endType) {
                Text("Never").tag(RecurrenceEndType.never)
                Text("On Date").tag(RecurrenceEndType.afterDate)
                Text("After Occurrences").tag(RecurrenceEndType.afterOccurrences)
            }

            if endType == .afterDate {
                DatePicker(
                    "End Date",
                    selection: $endDate,
                    displayedComponents: [.date]
                )
            }

            if endType == .afterOccurrences {
                Stepper("After \(endAfterOccurrences) occurrences", value: $endAfterOccurrences, in: 1...999)
            }
        } header: {
            Text("End Condition")
        }
    }

    private var previewSection: some View {
        Section {
            Text(previewText)
                .font(.subheadline)
        } header: {
            Text("Preview")
        }
    }

    // MARK: - Computed Properties

    private var frequencyUnit: String {
        switch frequency {
        case .daily:
            return interval == 1 ? "day" : "days"
        case .weekly:
            return interval == 1 ? "week" : "weeks"
        case .monthly:
            return interval == 1 ? "month" : "months"
        case .yearly:
            return interval == 1 ? "year" : "years"
        }
    }

    private var previewText: String {
        guard isRecurring else { return "No recurrence" }

        var text = "Repeats "

        switch frequency {
        case .daily:
            text += interval == 1 ? "daily" : "every \(interval) days"

        case .weekly:
            text += interval == 1 ? "weekly" : "every \(interval) weeks"
            if !selectedDaysOfWeek.isEmpty {
                let dayNames = selectedDaysOfWeek.sorted(by: { $0.rawValue < $1.rawValue })
                    .map { $0.shortName }
                text += " on " + dayNames.joined(separator: ", ")
            }

        case .monthly:
            text += interval == 1 ? "monthly" : "every \(interval) months"
            if isMonthYearOnly {
                text += " (month/year only)"
            } else {
                text += " on day \(dayOfMonth)"
            }

        case .yearly:
            text += interval == 1 ? "yearly" : "every \(interval) years"
            let monthName = Calendar.current.monthSymbols[monthOfYear - 1]
            text += " in \(monthName)"
            if !isMonthYearOnly {
                text += " on day \(dayOfMonth)"
            }
        }

        switch endType {
        case .never:
            break
        case .afterDate:
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            text += ", until \(formatter.string(from: endDate))"
        case .afterOccurrences:
            text += ", \(endAfterOccurrences) times"
        }

        return text
    }

    // MARK: - Methods

    private func loadExistingRule() {
        if let rule = recurrenceRule {
            isRecurring = true
            frequency = rule.frequency
            interval = rule.interval
            endType = rule.endType
            endDate = rule.endDate ?? Date()
            endAfterOccurrences = rule.endAfterOccurrences ?? 10

            if let days = rule.daysOfWeek {
                selectedDaysOfWeek = Set(days.compactMap { DayOfWeek(rawValue: $0) })
            }

            dayOfMonth = rule.dayOfMonth ?? 1
            monthOfYear = rule.monthOfYear ?? 1
            isMonthYearOnly = (rule.dayOfMonth == nil && frequency == .monthly) ||
                             (rule.dayOfMonth == nil && frequency == .yearly)
        }
    }

    private func saveRecurrenceRule() {
        if isRecurring {
            let rule = RecurrenceRule(
                frequency: frequency,
                interval: interval,
                daysOfWeek: frequency == .weekly ? selectedDaysOfWeek.map { $0.rawValue }.sorted() : nil,
                dayOfMonth: isMonthYearOnly ? nil : dayOfMonth,
                monthOfYear: frequency == .yearly ? monthOfYear : nil,
                endType: endType,
                endDate: endType == .afterDate ? endDate : nil,
                endAfterOccurrences: endType == .afterOccurrences ? endAfterOccurrences : nil
            )

            modelContext.insert(rule)
            recurrenceRule = rule
        } else {
            // Delete existing rule if turning off recurrence
            if let existingRule = recurrenceRule {
                modelContext.delete(existingRule)
            }
            recurrenceRule = nil
        }

        dismiss()
    }
}

// MARK: - Day Button Component

struct DayButton: View {
    let day: DayOfWeek
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(day.shortName)
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 44, height: 44)
                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}
