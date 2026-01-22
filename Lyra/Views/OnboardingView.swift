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
            description: "Import songs, create books and sets, and keep everything organized",
            icon: "book.fill",
            color: .green
        ),
        OnboardingPage(
            title: "Performance Mode",
            description: "Full-screen view with gesture controls, perfect for live performances",
            icon: "play.circle.fill",
            color: .orange
        ),
        OnboardingPage(
            title: "Smart Features",
            description: "Autoscroll, transpose, metronome, annotations, and more",
            icon: "sparkles",
            color: .purple
        ),
        OnboardingPage(
            title: "Track Your Progress",
            description: "Analytics and insights help you understand your performance patterns",
            icon: "chart.bar.fill",
            color: .pink
        ),
        OnboardingPage(
            title: "Works Offline",
            description: "All features work without internet. Perfect for venues with poor connectivity",
            icon: "wifi.slash",
            color: .red
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
