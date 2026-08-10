import SwiftUI
import VellureCore

struct TermsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                termsCard(
                    title: String(localized: "terms.s1.title"),
                    body: String(localized: "terms.s1.body")
                )
                termsCard(
                    title: String(localized: "terms.s2.title"),
                    body: String(localized: "terms.s2.body")
                )
                termsCard(
                    title: String(localized: "terms.s3.title"),
                    body: String(localized: "terms.s3.body")
                )

                Text("terms.updated")
                    .font(.system(size: 11.5))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.top, 4)
            }
            .padding(20)
        }
        .background(Theme.background)
        .navigationTitle(String(localized: "settings.terms"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func termsCard(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13.5, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text(body)
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Theme.divider, lineWidth: 1)
        )
    }
}
