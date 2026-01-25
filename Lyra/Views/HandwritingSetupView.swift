//
//  HandwritingSetupView.swift
//  Lyra
//
//  Phase 7.10: Enhanced OCR - Handwriting Training
//  First-time handwriting training interface
//

import SwiftUI
import SwiftData

struct HandwritingSetupView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var engine: HandwritingRecognitionEngine
    @State private var sampleImage: UIImage?
    @State private var recognizedText = ""
    @State private var correctedText = ""
    @State private var accuracyScore: Float = 0.0
    @State private var sampleCount = 0
    @State private var showingImagePicker = false

    init(modelContext: ModelContext) {
        _engine = State(initialValue: HandwritingRecognitionEngine(modelContext: modelContext))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Handwriting Setup")
                            .font(.largeTitle.bold())

                        Text("Train the OCR to recognize your handwriting for better accuracy.")
                            .foregroundStyle(.secondary)
                    }

                    // Progress
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Training Progress")
                                .font(.headline)

                            Spacer()

                            Text("\(sampleCount) samples")
                                .foregroundStyle(.secondary)
                        }

                        ProgressView(value: Double(sampleCount), total: 10.0)

                        if accuracyScore > 0 {
                            HStack {
                                Label("Accuracy: \(Int(accuracyScore * 100))%", systemImage: "checkmark.seal.fill")
                                    .foregroundStyle(.green)

                                Spacer()
                            }
                            .font(.subheadline)
                        }
                    }
                    .padding()
                    .background(.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Instructions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How it works:")
                            .font(.headline)

                        InstructionStep(number: 1, text: "Take a photo of your handwritten chord chart")
                        InstructionStep(number: 2, text: "Review the recognized text")
                        InstructionStep(number: 3, text: "Correct any mistakes")
                        InstructionStep(number: 4, text: "Repeat 5-10 times for best results")
                    }

                    // Sample input
                    if let image = sampleImage {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Current Sample")
                                .font(.headline)

                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                            if !recognizedText.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Recognized:")
                                        .font(.subheadline.bold())
                                    Text(recognizedText)
                                        .font(.system(.body, design: .monospaced))
                                        .padding()
                                        .background(.secondary.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))

                                    Text("Your Correction:")
                                        .font(.subheadline.bold())
                                    TextEditor(text: $correctedText)
                                        .font(.system(.body, design: .monospaced))
                                        .frame(height: 100)
                                        .padding(8)
                                        .background(.secondary.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))

                                    Button {
                                        submitSample()
                                    } label: {
                                        Label("Submit Correction", systemImage: "checkmark.circle.fill")
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(.green.gradient)
                                            .foregroundStyle(.white)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                            }
                        }
                    }

                    // Action button
                    Button {
                        showingImagePicker = true
                    } label: {
                        Label(sampleImage == nil ? "Add Sample" : "Add Another Sample", systemImage: "camera")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue.gradient)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    if sampleCount >= 5 {
                        Button {
                            dismiss()
                        } label: {
                            Label("Complete Setup", systemImage: "checkmark.circle.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.green.gradient)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $sampleImage, sourceType: .camera)
                    .onDisappear {
                        if sampleImage != nil {
                            processSample()
                        }
                    }
            }
        }
    }

    private func processSample() {
        guard let image = sampleImage else { return }

        Task {
            do {
                let result = try await engine.recognizeHandwriting(from: image)
                recognizedText = result.text
                correctedText = result.text
            } catch {
                print("Error processing sample: \(error)")
            }
        }
    }

    private func submitSample() {
        engine.learnFromSample(
            originalText: recognizedText,
            correctedText: correctedText,
            userId: "default"
        )

        sampleCount += 1
        accuracyScore = engine.getHandwritingAccuracy()

        // Reset for next sample
        sampleImage = nil
        recognizedText = ""
        correctedText = ""
    }
}

struct InstructionStep: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.headline.bold())
                .frame(width: 30, height: 30)
                .background(.blue.gradient)
                .foregroundStyle(.white)
                .clipShape(Circle())

            Text(text)
                .font(.body)
        }
    }
}
