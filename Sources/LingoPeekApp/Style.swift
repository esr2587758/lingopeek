import SwiftUI

extension Color {
    static let lingoAccent = Color(red: 110 / 255, green: 139 / 255, blue: 1.0)
    static let lingoAccent2 = Color(red: 138 / 255, green: 125 / 255, blue: 1.0)
    static let lingoAccentText = Color(red: 170 / 255, green: 182 / 255, blue: 1.0)
    static let lingoAccentWeak = Color(red: 110 / 255, green: 139 / 255, blue: 1.0, opacity: 0.16)
    static let lingoGlass = Color(red: 28 / 255, green: 30 / 255, blue: 40 / 255, opacity: 0.78)
    static let lingoGlass2 = Color(red: 40 / 255, green: 43 / 255, blue: 56 / 255, opacity: 0.70)
    static let lingoHairline = Color.white.opacity(0.09)
    static let lingoHairlineStrong = Color.white.opacity(0.15)
    static let lingoText = Color.white.opacity(0.95)
    static let lingoMuted = Color.white.opacity(0.60)
    static let lingoSubtle = Color.white.opacity(0.38)
    static let lingoPlaceholder = Color.white.opacity(0.38)
    static let lingoChip = Color.white.opacity(0.06)
    static let lingoChipHover = Color.white.opacity(0.11)
    static let lingoShadow = Color.black.opacity(0.75)
    static let lingoOuterStroke = Color.white.opacity(0.06)

    static let lingoPanel = lingoGlass
    static let lingoBar = lingoGlass
    static let lingoBand = Color.white.opacity(0.022)
    static let lingoSurface = lingoGlass2
}

struct FilledCapsuleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(configuration.isPressed ? Color.white.opacity(0.28) : Color.white.opacity(0.18))
            )
    }
}

struct PrimaryFooterButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.black)
            .padding(.horizontal, 10)
            .frame(height: 32)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(configuration.isPressed ? Color.white.opacity(0.82) : Color.white)
            )
    }
}

struct SecondaryFooterButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Color.lingoText)
            .padding(.horizontal, 10)
            .frame(height: 32)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(configuration.isPressed ? Color.white.opacity(0.16) : Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}
