//
//  AudioService.swift
//  Flashcards
//
//  Created by Greg Williams on 03.09.2025.
//

import AVFoundation

final class AudioService: ObservableObject {
    static let shared = AudioService()
    private init() {}   // ✅ no override

    private var player: AVAudioPlayer?
    private var previousVolume: Float?
    private var progressTimer: Timer?

    // Published state for UI binding
    @Published var isPlaying: Bool = false
    @Published var currentTrack: String?
    @Published var volume: Float = 0.6 {
        didSet { player?.volume = volume }
    }
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0

    // Call once at app start
    func configureSession() {
        do {
            // ✅ playback only, no ducking enforced
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("⚠️ Audio session config failed: \(error)")
        }
    }

    // Plays a track by filename (e.g. "lofi.mp3"), searching both root and "Audio/"
    func playSound(named name: String, loop: Bool = true, volume: Float? = nil) {
        // Try Audio/ first, then root
        let url: URL? =
            Bundle.main.url(forResource: name, withExtension: nil, subdirectory: "Audio")
            ?? Bundle.main.url(forResource: name, withExtension: nil)

        guard let url else {
            print("⚠️ Missing sound asset: \(name) (looked in root and 'Audio/') ")
            return
        }

        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.numberOfLoops = loop ? -1 : 0
            p.volume = volume ?? self.volume
            p.prepareToPlay()
            p.play()
            self.player = p
            self.isPlaying = true
            self.currentTrack = name
            self.duration = p.duration
            startProgressUpdates()
        } catch {
            print("⚠️ Failed to play \(name): \(error)")
        }
    }

    func pause() {
        player?.pause()
        isPlaying = false
        stopProgressUpdates()
    }

    func resume() {
        player?.play()
        isPlaying = true
        startProgressUpdates()
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        currentTrack = nil
        currentTime = 0
        duration = 0
        stopProgressUpdates()
    }

    func seek(to time: TimeInterval) {
        guard let p = player else { return }
        p.currentTime = time
        currentTime = time
    }

    // Returns all available .mp3 files in bundle root OR in an "Audio/" subfolder
    func availableTracks() -> [String] {
        var names: Set<String> = []

        // 1) Anything at bundle root
        if let root = Bundle.main.urls(forResourcesWithExtension: "mp3", subdirectory: nil) {
            root.forEach { names.insert($0.lastPathComponent) }
        }
        // 2) Anything under "Audio/" (works if you used a blue folder ref)
        if let sub = Bundle.main.urls(forResourcesWithExtension: "mp3", subdirectory: "Audio") {
            sub.forEach { names.insert($0.lastPathComponent) }
        }

        // Sort for a stable UI order
        return names.sorted()
    }

    // MARK: - Progress Updates
    private func startProgressUpdates() {
        stopProgressUpdates()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self, let p = self.player else { return }
            self.currentTime = p.currentTime
        }
    }

    private func stopProgressUpdates() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    // MARK: - Duck / Restore (kept for compatibility with SpeechReader)

    /// Gently lowers the internal player’s volume while TTS is speaking.
    func duckVolume(to value: Float = 0.2, fadeDuration: TimeInterval = 0.25) {
        guard let p = player else { return }
        if previousVolume == nil { previousVolume = p.volume }
        p.setVolume(value, fadeDuration: fadeDuration)
    }

    /// Restores the volume back to its previous value after TTS finishes.
    func restoreVolume(fadeDuration: TimeInterval = 0.25) {
        guard let p = player else { return }
        let target = previousVolume ?? 1.0
        p.setVolume(target, fadeDuration: fadeDuration)
        previousVolume = nil
    }
}
