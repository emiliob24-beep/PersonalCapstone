//
//  OnboardingView.swift
//  PersonalCapstone
//
//  Shown once on first launch (tracked via "hasSeenOnboarding" in
//  AppStorage) — no account/sign-up, just a quick welcome and a peek
//  at what the app does.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to Vehiko",
            body: "Your vehicle's maintenance, service history, and paperwork — all in one place.",
            systemImage: nil,
            showsLogo: true
        ),
        OnboardingPage(
            title: "Stay on Top of Maintenance",
            body: "Log service records, schedule upcoming tasks, and keep your Garage up to date for every vehicle you own.",
            systemImage: "wrench.and.screwdriver.fill",
            showsLogo: false
        ),
        OnboardingPage(
            title: "Scan Receipts, Skip the Typing",
            body: "Track parts you buy, and let Vehiko scan your receipts to fill in the cost, date, and shop automatically.",
            systemImage: "doc.text.viewfinder",
            showsLogo: false
        ),
        OnboardingPage(
            title: "More On the Way",
            body: "Family sharing is coming soon, so you'll be able to share a vehicle's records with the people who help you take care of it.",
            systemImage: "person.2.fill",
            showsLogo: false
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                if currentPage < pages.count - 1 {
                    Button("Skip") { finish() }
                        .padding()
                } else {
                    Color.clear.frame(height: 44)
                }
            }

            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button {
                if currentPage < pages.count - 1 {
                    withAnimation { currentPage += 1 }
                } else {
                    finish()
                }
            } label: {
                Text(currentPage == pages.count - 1 ? "Get Started" : "Next")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.appAccent)
            .padding()
        }
    }

    private func finish() {
        hasSeenOnboarding = true
    }
}

private struct OnboardingPage {
    let title: String
    let body: String
    let systemImage: String?
    let showsLogo: Bool
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            if page.showsLogo {
                Image("VehikoLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                    .shadow(radius: 8)
            } else if let systemImage = page.systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 64))
                    .foregroundStyle(Color.appAccent)
            }

            Text(LocalizedStringKey(page.title))
                .font(.title.bold())
                .multilineTextAlignment(.center)

            Text(LocalizedStringKey(page.body))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .padding()
    }
}
