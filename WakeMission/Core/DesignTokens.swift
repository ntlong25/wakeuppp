import SwiftUI

/// Layout tokens. Colours come from the system plus `AccentColor` in the asset catalog.
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

enum Radius {
    static let sm: CGFloat = 10
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
}

extension Color {
    /// Text/icons placed on an accent fill. White on the light accent, black on the dark one (contrast).
    static let onAccent = Color(.systemBackground)
}

extension View {
    func continuousCorners(_ radius: CGFloat) -> some View {
        clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

/// Shared title block for every mission, so the three screens read the same.
struct MissionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Text(title)
                .font(.title2.bold())
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}
