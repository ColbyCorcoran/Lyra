//
//  OCRReviewEditor.swift
//  Lyra
//
//  Phase 7.10: Enhanced OCR - Interactive Review Editor
//  Side-by-side image and text editing with correction suggestions
//

import SwiftUI

struct OCRReviewEditor: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss

    let result: EnhancedOCRResult
    let onSave: (EnhancedOCRResult) -> Void

    @State private var editedText: String
    @State private var corrections: [String: String] = [:]
    @State private var selectedReviewItem: ReviewItem?

    // MARK: - Initialization

    init(result: EnhancedOCRResult, onSave: @escaping (EnhancedOCRResult) -> Void) {
        self.result = result
        self.onSave = onSave
        _editedText = State(initialValue: result.correctedText)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Top: Image preview
                if let imageData = result.enhancedImage,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 250)
                        .background(Color.secondary.opacity(0.1))
                }

                Divider()

                // Bottom: Text editor with suggestions
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Confidence indicator
                        OCRQualityIndicator(confidence: result.confidenceBreakdown)

                        // Review items
                        if !result.reviewItems.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Suggestions")
                                    .font(.headline)

                                ForEach(result.reviewItems) { item in
                                    ReviewSuggestionCard(
                                        item: item,
                                        isSelected: selectedReviewItem?.id == item.id,
                                        onTap: { selectedReviewItem = item },
                                        onAccept: { acceptSuggestion(item) },
                                        onReject: { rejectSuggestion(item) }
                                    )
                                }
                            }
                        }

                        // Text editor
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recognized Text")
                                .font(.headline)

                            TextEditor(text: $editedText)
                                .font(.system(.body, design: .monospaced))
                                .frame(minHeight: 300)
                                .padding(8)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        // Correction count
                        if !corrections.isEmpty {
                            Text("\(corrections.count) correction(s) applied")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Review & Correct")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func acceptSuggestion(_ item: ReviewItem) {
        guard let suggestion = item.suggestedCorrection else { return }

        // Apply correction to text
        editedText = editedText.replacingOccurrences(of: item.originalText, with: suggestion)

        // Store correction
        corrections[item.originalText] = suggestion
    }

    private func rejectSuggestion(_ item: ReviewItem) {
        // Remove from review items
        selectedReviewItem = nil
    }

    private func saveChanges() {
        var updatedResult = result
        updatedResult.correctedText = editedText

        // Apply corrections (this will also update learning)
        onSave(updatedResult)
        dismiss()
    }
}

// MARK: - Supporting Views

struct ReviewSuggestionCard: View {
    let item: ReviewItem
    let isSelected: Bool
    let onTap: () -> Void
    let onAccept: () -> Void
    let onReject: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Original:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(item.originalText)
                            .font(.body.monospaced())
                            .foregroundStyle(.red)
                    }

                    if let suggestion = item.suggestedCorrection {
                        HStack {
                            Text("Suggested:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(suggestion)
                                .font(.body.monospaced())
                                .foregroundStyle(.green)
                        }
                    }
                }

                Spacer()

                // Confidence badge
                Text("\(Int(item.confidence * 100))%")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(confidenceColor.opacity(0.2))
                    .foregroundStyle(confidenceColor)
                    .clipShape(Capsule())
            }

            Text(item.correctionReason)
                .font(.caption)
                .foregroundStyle(.secondary)

            // Actions
            if item.suggestedCorrection != nil {
                HStack(spacing: 12) {
                    Button {
                        onAccept()
                    } label: {
                        Label("Accept", systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(.green.gradient)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    Button {
                        onReject()
                    } label: {
                        Label("Reject", systemImage: "xmark.circle.fill")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(.red.gradient)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.1) : Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            onTap()
        }
    }

    private var confidenceColor: Color {
        if item.confidence >= 0.7 {
            return .green
        } else if item.confidence >= 0.5 {
            return .orange
        } else {
            return .red
        }
    }
}
