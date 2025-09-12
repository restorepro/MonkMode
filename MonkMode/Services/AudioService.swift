//
//  AudioService.swift
//  Flashcards
//
//  Created by Greg Williams on 03.09.2025.
//

import AVFoundation

final class AudioService: ObservableObject {
    static let shared = AudioService()
    private init() {
        loadPreferences()   // 👈 restore last settings on init
    }

    private var player: AVAudioPlayer?
    private var previousVolume: Float?
    private var progressTimer: Timer?

    // Published state for UI binding
    @Published var isPlaying: Bool = false
    @Published var currentTrack: String? {
        didSet { savePreferences() }
    }
    @Published var volume: Float = 0.6 {
        didSet {
            player?.volume = volume
            savePreferences()
        }
    }
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0

    // Call once at app start
    func configureSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("⚠️ Audio session config failed: \(error)")
        }
    }

    // Plays a track by filename (e.g. "lofi.mp3")
    func playSound(named name: String, loop: Bool = true, volume: Float? = nil) {
        let url: URL? =
            Bundle.main.url(forResource: name, withExtension: nil, subdirectory: "Audio")
            ?? Bundle.main.url(forResource: name, withExtension: nil)

        guard let url else {
            print("⚠️ Missing sound asset: \(name)")
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

    func availableTracks() -> [String] {
        var names: Set<String> = []
        if let root = Bundle.main.urls(forResourcesWithExtension: "mp3", subdirectory: nil) {
            root.forEach { names.insert($0.lastPathComponent) }
        }
        if let sub = Bundle.main.urls(forResourcesWithExtension: "mp3", subdirectory: "Audio") {
            sub.forEach { names.insert($0.lastPathComponent) }
        }
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

    // MARK: - Preferences Persistence
    private let defaults = UserDefaults.standard
    private let volumeKey = "audio_volume"
    private let trackKey = "audio_track"

    private func savePreferences() {
        defaults.set(volume, forKey: volumeKey)
        defaults.set(currentTrack, forKey: trackKey)
    }

    private func loadPreferences() {
        if defaults.object(forKey: volumeKey) != nil {
            volume = defaults.float(forKey: volumeKey)
        }
        if let savedTrack = defaults.string(forKey: trackKey) {
            currentTrack = savedTrack
            // Auto-play last track if available
            if availableTracks().contains(savedTrack) {
                playSound(named: savedTrack)
            }
        }
    }

    // MARK: - Duck / Restore (kept for compatibility with SpeechReader)
    func duckVolume(to value: Float = 0.2, fadeDuration: TimeInterval = 0.25) {
        guard let p = player else { return }
        if previousVolume == nil { previousVolume = p.volume }
        p.setVolume(value, fadeDuration: fadeDuration)
    }

    func restoreVolume(fadeDuration: TimeInterval = 0.25) {
        guard let p = player else { return }
        let target = previousVolume ?? 1.0
        p.setVolume(target, fadeDuration: fadeDuration)
        previousVolume = nil
    }
}
