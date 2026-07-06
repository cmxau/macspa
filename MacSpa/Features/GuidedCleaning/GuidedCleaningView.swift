// GuidedCleaningView.swift
import SwiftUI

struct GuidedCleaningView: View {
    @Environment(AppState.self) private var appState
    @Environment(EventTapService.self) private var eventTap
    @Environment(\.modelContext) private var modelContext
    @AppStorage("durKeyboard") private var durKeyboard = CleaningDurations.defaultKeyboard
    @AppStorage("durTrackpad") private var durTrackpad = CleaningDurations.defaultTrackpad
    @AppStorage("durDisplay")  private var durDisplay  = CleaningDurations.defaultDisplay

    fileprivate struct Surface: Identifiable {
        let id = UUID()
        let icon: String; let title: String; let duration: String
        let tips: [String]; let accentColor: Color; let kind: DeviceKind
    }

    // All surfaces share the active brand accent so the whole UI stays one color.
    // Durations follow the user's Settings values (with sensible defaults).
    private var surfaces: [Surface] {
        [
            Surface(icon: "keyboard.fill", title: "Keyboard", duration: CleaningDurations.label(durKeyboard),
                    tips: ["Circular motions", "No harsh solvents", "Tilt to shake crumbs"],
                    accentColor: .spaPrimary, kind: .keyboard),
            Surface(icon: "square.grid.2x2.fill", title: "Trackpad", duration: CleaningDurations.label(durTrackpad),
                    tips: ["Dry cloth only", "Buff, don't press", "Restores that glide"],
                    accentColor: .spaPrimary, kind: .trackpad),
            Surface(icon: "display", title: "Display", duration: CleaningDurations.label(durDisplay),
                    tips: ["Top to bottom", "Barely damp", "Never spray direct"],
                    accentColor: .spaPrimary, kind: .display),
        ]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(eyebrow: "Guided Cleaning", title: "Rituals for every surface.")
                    Text("Pick a ritual. We\u{2019}ll pause input, guide the steps, and celebrate together at the end.")
                        .font(.body).foregroundStyle(.secondary).frame(maxWidth: 520)
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
                    ForEach(surfaces) { surface in
                        SurfaceCard(surface: surface) {
                            // Individual ritual: run only this device's stage.
                            SessionWindowController.shared.show(appState: appState, eventTap: eventTap,
                                                                container: modelContext.container, startKind: surface.kind)
                        }
                    }
                }

            }
            .padding(2)
            .softIn()
        }
    }
}

private struct SurfaceCard: View {
    let surface: GuidedCleaningView.Surface
    let onBegin: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Illustration header - device drawing under a wiping cloth
            ZStack {
                LinearGradient(colors: [surface.accentColor.opacity(0.22), surface.accentColor.opacity(0.08)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                DeviceArt(kind: surface.kind, accent: surface.accentColor)
                    .frame(width: 118, height: 72)
                CleaningClothView(width: 52, height: 36, cornerRadius: 9, logoSize: 9, tint: surface.accentColor)
                    .wipe()
                Image(systemName: "sparkles")
                    .foregroundStyle(surface.accentColor)
                    .offset(x: 40, y: -24)
                    .sparkle()
            }
            .frame(height: 128)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 10) {
                Group {
                    if surface.kind == .trackpad {
                        TrackpadGlyphTile(color: surface.accentColor, size: 42)
                    } else {
                        IconTile(systemName: surface.icon, color: surface.accentColor, size: 42, symbolSize: 18)
                    }
                }
                .padding(.top, 4)
                Text(surface.title).font(.title2.weight(.bold))
                Label(surface.duration, systemImage: "clock")
                    .font(.caption).foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(surface.tips, id: \.self) { tip in
                        HStack(spacing: 8) {
                            Circle().fill(surface.accentColor.opacity(0.7)).frame(width: 5, height: 5)
                            Text(tip).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.top, 2)
                Button("Begin") { onBegin() }
                    .buttonStyle(PrimaryButtonStyle(icon: "play.fill", size: .large, fullWidth: true))
                    .padding(.top, 6)
            }
            .padding(16)
        }
        .surfaceMaterial(cornerRadius: 22)
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.spaHairline, lineWidth: 1))
        .hoverLift()
    }
}
