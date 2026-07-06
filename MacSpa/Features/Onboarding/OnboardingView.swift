import SwiftUI
@preconcurrency import AppKit

struct OnboardingView: View {
    @Environment(AppState.self) private var appState

    @AppStorage("storeHistory") private var storeHistory = true
    @AppStorage("launchAtLogin") private var launchAtLogin = false

    @State private var stepIndex = 0
    @State private var axTrusted = AXIsProcessTrusted()

    private let stepCount = 5
    private var isLast: Bool { stepIndex == stepCount - 1 }
    private var accent: Color {
        [.spaPrimary, .spaSecondary, .spaSuccess, .spaCoral, .spaSuccess][stepIndex]
    }

    var body: some View {
        ZStack {
            HeroBackground()

            VStack(spacing: 0) {
                topBar
                Spacer()

                Group {
                    switch stepIndex {
                    case 0: welcome
                    case 1: features
                    case 2: setup
                    case 3: permission
                    default: finishStep
                    }
                }
                .id(stepIndex)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)))
                .padding(.horizontal, 60)
                .frame(maxWidth: 760)

                Spacer()
                bottomNav
            }
        }
        .frame(minWidth: 960, minHeight: 660)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: stepIndex)
    }

    // MARK: Chrome

    private var topBar: some View {
        HStack {
            HStack(spacing: 9) {
                AppLogo().frame(width: 30, height: 30)
                Text("MacSpa").font(.headline.weight(.semibold))
            }
            Spacer()
            HStack(spacing: 5) {
                ForEach(0..<stepCount, id: \.self) { i in
                    Capsule()
                        .fill(i <= stepIndex ? accent : Color.secondary.opacity(0.22))
                        .frame(width: i == stepIndex ? 26 : 7, height: 6)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: stepIndex)
                }
            }
            Spacer()
            Button("Skip") { finish() }
                .font(.subheadline).foregroundStyle(.secondary).buttonStyle(.plain)
        }
        .padding(.horizontal, 40).padding(.top, 28)
    }

    private var bottomNav: some View {
        HStack(spacing: 14) {
            if stepIndex > 0 {
                Button("Back") { withAnimation { stepIndex -= 1 } }
                    .font(.subheadline).foregroundStyle(.secondary).buttonStyle(.plain)
            }
            Spacer()
            Button(isLast ? "Enter MacSpa" : "Continue") {
                if isLast { finish() } else { withAnimation { stepIndex += 1 } }
            }
            .buttonStyle(CTAStyle(tint: accent))
        }
        .padding(.horizontal, 60).padding(.bottom, 34)
        .frame(maxWidth: 760)
    }

    // MARK: Steps

    private var welcome: some View {
        VStack(spacing: 22) {
            ZStack {
                AppLogo().frame(width: 150, height: 150)
                    .float()
                Image(systemName: "sparkle").font(.system(size: 20))
                    .foregroundStyle(Color.spaSecondary).offset(x: 82, y: -74).sparkle()
                Image(systemName: "sparkle").font(.system(size: 14))
                    .foregroundStyle(Color.spaSuccess).offset(x: -84, y: 70).sparkle(delay: 0.7)
            }
            Text("Meet MacSpa.")
                .font(.system(size: 52, weight: .bold)).tracking(-1.5)
            Text("A calm companion that helps you care for your Mac, one gentle spa session at a time.")
                .font(.title3).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).frame(maxWidth: 460)
        }
        .frame(maxWidth: .infinity)
    }

    private let featureList: [(String, String, String, Color)] = [
        ("lock.shield.fill", "Safe Cleaning Mode", "Pauses your keyboard and trackpad so you can wipe without a single stray tap.", .spaPrimary),
        ("sparkles", "Guided Rituals", "Step-by-step cleaning for your keyboard, trackpad, and display.", .spaSecondary),
        ("heart.fill", "Device Wellness", "A live score and mood, grown from your cleaning habits.", .spaCoral),
        ("rosette", "Achievements", "Unlock milestones as you care for your Mac over time.", .spaWarning),
        ("bell.fill", "Gentle Reminders", "Soft nudges to keep the spa routine going.", .spaPrimary),
    ]

    private var features: some View {
        VStack(alignment: .leading, spacing: 18) {
            stepHeader(tag: "WHAT\u{2019}S INSIDE", title: "Everything your Mac needs.")
            VStack(spacing: 12) {
                ForEach(Array(featureList.enumerated()), id: \.offset) { i, f in
                    FeatureRow(icon: f.0, title: f.1, detail: f.2, tint: f.3, index: i)
                }
            }
        }
    }

    private var setup: some View {
        VStack(alignment: .leading, spacing: 18) {
            stepHeader(tag: "SET THINGS UP", title: "Make it yours.")
            VStack(spacing: 12) {
                SetupToggle(icon: "internaldrive.fill", tint: .spaPrimary,
                            title: "Local history",
                            detail: "Keep your cleaning sessions saved on this Mac.",
                            isOn: $storeHistory)
                SetupToggle(icon: "power", tint: .spaSecondary,
                            title: "Launch at login",
                            detail: "Recommended so tracking never misses a session.",
                            recommended: true,
                            isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, on in launchAtLogin = LoginItemService.setEnabled(on) }
            }
        }
    }

    private var permission: some View {
        VStack(spacing: 20) {
            IconTile(systemName: "lock.shield.fill", color: .spaCoral, size: 72, symbolSize: 32)
                .breathe()
            Text("One quick permission.")
                .font(.system(size: 40, weight: .bold)).tracking(-1)
                .multilineTextAlignment(.center)
            Text("MacSpa needs Accessibility access to safely pause input during a cleaning session. Nothing else is ever watched.")
                .font(.title3).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).frame(maxWidth: 480)

            HStack(spacing: 12) {
                Image(systemName: axTrusted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(axTrusted ? Color.spaSuccess : Color.spaWarning)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Accessibility Access").font(.subheadline.weight(.semibold))
                    Text(axTrusted ? "Granted" : "Not granted yet")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if axTrusted {
                    Button("Re-check") { axTrusted = AXIsProcessTrusted() }
                        .buttonStyle(.bordered).controlSize(.small)
                } else {
                    Button("Grant") { requestAccess() }
                        .buttonStyle(.borderedProminent).tint(Color.spaPrimary).controlSize(.small)
                }
            }
            .padding(14)
            .frame(maxWidth: 440)
            .surfaceMaterial(cornerRadius: 16)
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.spaHairline))
        }
        .frame(maxWidth: .infinity)
        .onAppear { axTrusted = AXIsProcessTrusted() }
    }

    private var finishStep: some View {
        VStack(spacing: 20) {
            IconTile(systemName: "checkmark.seal.fill", color: .spaSuccess, size: 84, symbolSize: 40)
                .breathe()
            Text("You\u{2019}re all set.")
                .font(.system(size: 46, weight: .bold)).tracking(-1)
            Text("Your Mac is ready for its first spa. Enjoy the calm.")
                .font(.title3).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).frame(maxWidth: 420)
        }
        .frame(maxWidth: .infinity)
    }

    private func stepHeader(tag: String, title: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(tag).font(.caption.weight(.semibold)).tracking(1.2).foregroundStyle(accent)
            Text(title).font(.system(size: 40, weight: .bold)).tracking(-1)
        }
    }

    // MARK: Actions

    private func requestAccess() {
        let opts = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(opts)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    private func finish() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        appState.showOnboarding = false
    }
}

// MARK: - Feature row (staggered appear)

private struct FeatureRow: View {
    let icon: String; let title: String; let detail: String; let tint: Color; let index: Int
    @State private var shown = false

    var body: some View {
        HStack(spacing: 14) {
            IconTile(systemName: icon, color: tint, size: 46, symbolSize: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .surfaceMaterial(cornerRadius: 16)
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.spaHairline, lineWidth: 1))
        .opacity(shown ? 1 : 0)
        .offset(x: shown ? 0 : 24)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85).delay(Double(index) * 0.07)) {
                shown = true
            }
        }
    }
}

// MARK: - Setup toggle

private struct SetupToggle: View {
    let icon: String; let tint: Color; let title: String; let detail: String
    var recommended = false
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            IconTile(systemName: icon, color: tint, size: 46, symbolSize: 20)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title).font(.headline)
                    if recommended {
                        Text("RECOMMENDED").font(.caption2.weight(.bold)).tracking(0.5)
                            .foregroundStyle(Color.spaSuccess)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.spaSuccess.opacity(0.14), in: Capsule())
                    }
                }
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Toggle("", isOn: $isOn).toggleStyle(.switch).labelsHidden()
        }
        .padding(14)
        .surfaceMaterial(cornerRadius: 16)
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.spaHairline, lineWidth: 1))
    }
}

// MARK: - CTA button

private struct CTAStyle: ButtonStyle {
    let tint: Color
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.label
            Image(systemName: "chevron.right")
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 24).padding(.vertical, 12)
        .background(tint.gradient, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}
