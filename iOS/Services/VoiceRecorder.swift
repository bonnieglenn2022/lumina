import Foundation
import AVFoundation

/// Records affirmations in the user's own voice (Premium). Files stay on the device.
@MainActor
final class VoiceRecorder: NSObject, ObservableObject, AVAudioPlayerDelegate {
    static let shared = VoiceRecorder()

    @Published private(set) var isRecording = false
    @Published private(set) var playingID: String?
    @Published private(set) var elapsed: TimeInterval = 0

    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var timer: Timer?
    let maxDuration: TimeInterval = 60

    private var folder: URL {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Recordings", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    func fileURL(for id: String) -> URL {
        let safe = id.replacingOccurrences(of: "/", with: "-")
        return folder.appendingPathComponent("\(safe).m4a")
    }

    func hasRecording(_ id: String) -> Bool {
        FileManager.default.fileExists(atPath: fileURL(for: id).path)
    }

    func requestPermission() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }

    func startRecording(for id: String) async -> Bool {
        guard await requestPermission() else { return false }
        stopPlayback()
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            let recorder = try AVAudioRecorder(url: fileURL(for: id), settings: settings)
            recorder.record(forDuration: maxDuration)
            self.recorder = recorder
            isRecording = true
            elapsed = 0
            timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    guard let self, let r = self.recorder else { return }
                    self.elapsed = r.currentTime
                    if !r.isRecording { self.stopRecording() }
                }
            }
            return true
        } catch {
            return false
        }
    }

    func stopRecording() {
        recorder?.stop()
        recorder = nil
        timer?.invalidate()
        timer = nil
        isRecording = false
    }

    func play(_ id: String) {
        stopPlayback()
        guard hasRecording(id) else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
        player = try? AVAudioPlayer(contentsOf: fileURL(for: id))
        player?.delegate = self
        player?.play()
        playingID = id
    }

    func stopPlayback() {
        player?.stop()
        player = nil
        playingID = nil
    }

    func delete(_ id: String) {
        if playingID == id { stopPlayback() }
        try? FileManager.default.removeItem(at: fileURL(for: id))
        objectWillChange.send()
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in self.playingID = nil }
    }
}
