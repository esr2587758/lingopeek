import SwiftUI

extension Color {
    static let lingoPanel = Color(red: 0.11, green: 0.11, blue: 0.12)
    static let lingoBar = Color(red: 0.12, green: 0.12, blue: 0.13)
    static let lingoText = Color(red: 0.88, green: 0.88, blue: 0.9)
    static let lingoMuted = Color(red: 0.63, green: 0.63, blue: 0.67)
    static let lingoAccent = Color(red: 0.78, green: 0.78, blue: 0.8)
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
