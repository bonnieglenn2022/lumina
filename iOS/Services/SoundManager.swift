import Foundation
import AVFoundation

/// Ambient soundscapes for Breathe & Wind-down.
/// Each one is generated live (no download needed). If you later add a licensed nature recording
/// named e.g. "rain.m4a" to the app bundle, Lumina plays that file instead.
enum Soundscape: String, CaseIterable, Identifiable, Codable {
    case none, rain, ocean, wind, brown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: return "Silence"
        case .rain: return "Rain"
        case .ocean: return "Ocean"
        case .wind: return "Wind"
        case .brown: return "Brown noise"
        }
    }

    var symbol: String {
        switch self {
        case .none: return "speaker.slash"
        case .rain: return "cloud.rain"
        case .ocean: return "water.waves"
        case .wind: return "wind"
        case .brown: return "waveform"
        }
    }

    var isFree: Bool { self == .none || self == .rain || self == .brown }
}

final class SoundManager {
    static let shared = SoundManager()

    private var effectPlayer: AVAudioPlayer?
    private var loopPlayer: AVAudioPlayer?
    private var engine: AVAudioEngine?
    private var fadeTask: Task<Void, Never>?
    private(set) var current: Soundscape = .none

    // MARK: UI sounds

    /// Soft completion tone for "I receive this". Respects the silent switch.
    func playComplete(enabled: Bool) {
        guard enabled, current == .none else { return }
        play(effect: "lumina_complete")
    }

    func playChime(enabled: Bool) {
        guard enabled else { return }
        play(effect: "lumina_chime")
    }

    private func play(effect name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else { return }
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
        effectPlayer = try? AVAudioPlayer(contentsOf: url)
        effectPlayer?.volume = 0.6
        effectPlayer?.play()
    }

    // MARK: Soundscapes

    func start(_ soundscape: Soundscape, volume: Float = 0.7) {
        stop(fade: false)
        guard soundscape != .none else { return }
        current = soundscape
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, options: [.mixWithOthers])
        try? session.setActive(true)

        if let url = Bundle.main.url(forResource: soundscape.rawValue, withExtension: "m4a"),
           let player = try? AVAudioPlayer(contentsOf: url) {
            player.numberOfLoops = -1
            player.volume = 0
            player.play()
            player.setVolume(volume, fadeDuration: 2)
            loopPlayer = player
            return
        }

        let engine = AVAudioEngine()
        let sampleRate = engine.outputNode.outputFormat(forBus: 0).sampleRate > 0
            ? engine.outputNode.outputFormat(forBus: 0).sampleRate : 44_100
        let generator = NoiseGenerator(kind: soundscape, sampleRate: sampleRate)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
        let node = AVAudioSourceNode(format: format) { _, _, frameCount, audioBufferList in
            let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frame in 0..<Int(frameCount) {
                let value = generator.next()
                for buffer in buffers {
                    let samples = UnsafeMutableBufferPointer<Float>(buffer)
                    samples[frame] = value
                }
            }
            return noErr
        }
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 0
        do {
            try engine.start()
            self.engine = engine
            fade(to: volume, over: 2)
        } catch {
            current = .none
        }
    }

    func stop(fade: Bool = true) {
        fadeTask?.cancel()
        let endEngine = engine
        let endPlayer = loopPlayer
        engine = nil
        loopPlayer = nil
        current = .none
        guard fade else {
            endEngine?.stop()
            endPlayer?.stop()
            return
        }
        endPlayer?.setVolume(0, fadeDuration: 1.5)
        Task {
            if let endEngine {
                for step in stride(from: 10, through: 0, by: -1) {
                    endEngine.mainMixerNode.outputVolume *= Float(step) / 10
                    try? await Task.sleep(for: .milliseconds(150))
                }
                endEngine.stop()
            } else {
                try? await Task.sleep(for: .seconds(1.6))
            }
            endPlayer?.stop()
        }
    }

    private func fade(to target: Float, over seconds: Double) {
        fadeTask?.cancel()
        fadeTask = Task { [weak self] in
            let steps = 20
            for i in 1...steps {
                guard !Task.isCancelled else { return }
                self?.engine?.mainMixerNode.outputVolume = target * Float(i) / Float(steps)
                try? await Task.sleep(for: .seconds(seconds / Double(steps)))
            }
        }
    }
}

/// Real-time noise synthesis. Kept allocation-free for the audio thread.
private final class NoiseGenerator {
    private let kind: Soundscape
    private let sampleRate: Double
    private var seed: UInt32 = 22_222
    private var brown: Float = 0
    private var pink0: Float = 0, pink1: Float = 0, pink2: Float = 0
    private var smooth: Float = 0
    private var t: Double = 0

    init(kind: Soundscape, sampleRate: Double) {
        self.kind = kind
        self.sampleRate = sampleRate
    }

    private func white() -> Float {
        seed ^= seed << 13
        seed ^= seed >> 17
        seed ^= seed << 5
        return Float(seed) / Float(UInt32.max) * 2 - 1
    }

    func next() -> Float {
        let w = white()
        t += 1 / sampleRate
        brown = (brown + 0.02 * w) / 1.02
        pink0 = 0.99765 * pink0 + w * 0.0990460
        pink1 = 0.96300 * pink1 + w * 0.2965164
        pink2 = 0.57000 * pink2 + w * 1.0526913
        let pink = (pink0 + pink1 + pink2 + w * 0.1848) * 0.11

        switch kind {
        case .none:
            return 0
        case .brown:
            return brown * 3.2
        case .rain:
            // Pink noise with a soft high-frequency lift, like steady rainfall.
            return (pink * 0.55 + w * 0.06) * 0.8
        case .ocean:
            // Brown noise swelling every ~11 seconds, like waves.
            let swell = Float(0.25 + 0.75 * pow(0.5 + 0.5 * sin(2 * .pi * t / 11), 2))
            return brown * 3.2 * swell
        case .wind:
            // Low-passed noise whose brightness drifts slowly.
            let drift = Float(0.004 + 0.02 * (0.5 + 0.5 * sin(2 * .pi * t / 17)))
            smooth += drift * (pink - smooth)
            return smooth * 6
        }
    }
}
