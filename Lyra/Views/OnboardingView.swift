//
//  OnboardingView.swift
//  Lyra
//
//  Onboarding flow for new users
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("onboarding.completed") private var hasCompletedOnboarding: Bool = false

    @State private var currentPage: Int = 0
    @State private var showPermissions: Bool = false

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to Lyra",
            description: "The ultimate chord chart app for musicians, designed for live performance",
            icon: "music.note",
            color: .blue
        ),
        OnboardingPage(
            title: "Organize Your Library",
            description: "Create books and sets, import from OnSong, and keep everything organized",
            icon: "book.fill",
            color: .green
        ),
        OnboardingPage(
            title: "Performance Features",
            description: "Autoscroll, transpose, metronome, backing tracks, and low light mode",
            icon: "play.circle.fill",
            color: .purple
        ),
        OnboardingPage(
            title: "Customize Everything",
            description: "Fonts, colors, layouts, templates, and per-song display settings",
            icon: "paintbrush.fill",
            color: .orange
        ),
        OnboardingPage(
            title: "Annotations & Drawing",
            description: "Add notes and draw on your charts for performance cues and reminders",
            icon: "pencil.tip.crop.circle",
            color: .pink
        )
    ]

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [pages[currentPage].color.opacity(0.3), pages[currentPage].color.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()

                    Button {
                        completeOnboarding()
                    } label: {
                        Text("Skip")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .padding()
                    }
                }
                .padding(.top, 20)

                Spacer()

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .frame(maxHeight: .infinity)

                Spacer()

                // Bottom buttons
                VStack(spacing: 16) {
                    if currentPage == pages.count - 1 {
                        // Get Started button
                        Button {
                            completeOnboarding()
                        } label: {
                            HStack {
                                Text("Get Started")
                                    .fontWeight(.semibold)
                                Image(systemName: "arrow.right")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(pages[currentPage].color)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    } else {
                        // Next button
                        Button {
                            withAnimation {
                                currentPage += 1
                            }
                        } label: {
                            HStack {
                                Text("Next")
                                    .fontWeight(.semibold)
                                Image(systemName: "arrow.right")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(pages[currentPage].color)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .animation(.easeInOut, value: currentPage)
    }

    private func completeOnboarding() {
        hasCompletedOnboarding = true
        dismiss()
    }
}

// MARK: - Onboarding Page Model

struct OnboardingPage {
    let title: String
    let description: String
    let icon: String
    let color: Color
}

// MARK: - Onboarding Page View

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 32) {
            // Icon
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.2))
                    .frame(width: 150, height: 150)

                Image(systemName: page.icon)
                    .font(.system(size: 60))
                    .foregroundStyle(page.color)
            }

            // Title and description
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 32, weight: .bold))
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
}
