//
//  AudioService.swift
//  Flashcards
//
//  Created by Greg Williams on 03.09.2025.
//

import AVFoundation

final class AudioService {
    static let shared = AudioService()
    private init() {}

    private var player: AVAudioPlayer?
    private var previousVolume: Float?

    // Call once at app start
    func configureSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("⚠️ Audio session config failed: \(error)")
        }
    }

    /// Optional helper if you play background audio (noise, music, etc.)
    func playSound(named name: String, loop: Bool = true, volume: Float = 0.6) {
        guard let url = Bundle.main.url(forResource: name, withExtension: nil) else {
            print("⚠️ Missing sound asset: \(name)")
            return
        }
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.numberOfLoops = loop ? -1 : 0
            p.volume = volume
            p.prepareToPlay()
            p.play()
            self.player = p
        } catch {
            print("⚠️ Failed to play \(name): \(error)")
        }
    }

    func stop() {
        player?.stop()
        player = nil
    }

    // MARK: - Duck / Restore (used by SpeechReader)

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
