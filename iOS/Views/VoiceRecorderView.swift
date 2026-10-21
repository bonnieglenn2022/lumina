import SwiftUI

/// Record an affirmation in your own voice (Premium).
struct VoiceRecorderView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var voice = VoiceRecorder.shared
    let affirmation: Affirmation
    @State private var permissionDenied = false
    @State private var pulse = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                VStack(spacing: 28) {
                    Text("Read it slowly, as if it's already true.")
                        .font(Theme.text(15))
                        .foregroundStyle(Theme.secondary)

                    Text(affirmation.text)
                        .font(Theme.serif(28))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)

                    Spacer()

                    Text(timeText)
                        .font(Theme.display(34, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(voice.isRecording ? Theme.glow : Theme.secondary)

                    Button(action: toggle) {
                        ZStack {
                            Circle()
                                .fill(Theme.glow.opacity(0.18))
                                .frame(width: 120, height: 120)
                                .scaleEffect(voice.isRecording && pulse ? 1.15 : 1)
                            Circle()
                                .fill(voice.isRecording ? Theme.glow : Theme.accent)
                                .frame(width: 84, height: 84)
                            Image(systemName: voice.isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 30, weight: .semibold))
                                .foregroundStyle(Theme.onAccent)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(voice.isRecording ? "Stop recording" : "Start recording")
                    .sensoryFeedback(.impact(weight: .medium), trigger: voice.isRecording)

                    if voice.hasRecording(affirmation.id) && !voice.isRecording {
                        HStack(spacing: 12) {
                            Button {
                                voice.playingID == affirmation.id ? voice.stopPlayback() : voice.play(affirmation.id)
                            } label: {
                                Label(voice.playingID == affirmation.id ? "Stop" : "Listen back",
                                      systemImage: voice.playingID == affirmation.id ? "stop.fill" : "play.fill")
                            }
                            .buttonStyle(.bordered)
                            Button("Use this") { dismiss() }
                                .buttonStyle(.borderedProminent)
                        }
                        .tint(Theme.accent)
                    } else {
                        Text("Up to 60 seconds. Recordings stay on your iPhone.")
                            .font(Theme.text(13))
                            .foregroundStyle(Theme.secondary)
                    }
                    Spacer().frame(height: 12)
                }
                .padding(24)
            }
            .navigationTitle("Your Voice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { voice.stopRecording(); voice.stopPlayback(); dismiss() }
                }
            }
            .alert("Microphone access needed", isPresented: $permissionDenied) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Turn on microphone access for Lumina in Settings to record your voice.")
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) { pulse = true }
            }
        }
    }

    private var timeText: String {
        let s = Int(voice.elapsed)
        return String(format: "0:%02d", min(s, 59))
    }

    private func toggle() {
        if voice.isRecording {
            voice.stopRecording()
        } else {
            Task {
                let ok = await voice.startRecording(for: affirmation.id)
                if !ok { permissionDenied = true }
            }
        }
    }
}
