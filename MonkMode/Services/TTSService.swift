//
//  TTSService.swift
//  Flashcards
//
//  Created by Greg Williams on 03.09.2025.
//

import AVFoundation

final class TTSService: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = TTSService()
    private override init() {
        super.init()
        synth.delegate = self
    }

    private let synth = AVSpeechSynthesizer()

    // Map utterance -> id and completion
    private var utteranceIDs: [ObjectIdentifier: UUID] = [:]
    private var completions: [UUID: () -> Void] = [:]

    @discardableResult
    func speak(
        text: String,
        voiceId: String? = nil,
        rate: Float = AVSpeechUtteranceDefaultSpeechRate,
        pitch: Float = 1.0,
        volume: Float = 1.0,
        onFinish: (() -> Void)? = nil
    ) -> UUID {
        let id = UUID()
        let utt = AVSpeechUtterance(string: text)
        utt.rate = rate
        utt.pitchMultiplier = pitch
        utt.volume = volume

        if let voiceId, let voice = AVSpeechSynthesisVoice(identifier: voiceId) {
            utt.voice = voice
        } else {
            // Fallback if a specific Siri voice isn’t available on the device/simulator
            utt.voice = AVSpeechSynthesisVoice(language: "en-US")
        }

        let key = ObjectIdentifier(utt)
        utteranceIDs[key] = id
        if let onFinish { completions[id] = onFinish }

        synth.speak(utt)
        return id
    }

    func pause() { synth.pauseSpeaking(at: .immediate) }
    func `continue`() { synth.continueSpeaking() }
    func stop() {
        synth.stopSpeaking(at: .immediate)
        utteranceIDs.removeAll()
        completions.removeAll()
    }

    var isSpeaking: Bool { synth.isSpeaking }

    // MARK: - AVSpeechSynthesizerDelegate

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let key = ObjectIdentifier(utterance)
        guard let id = utteranceIDs.removeValue(forKey: key) else { return }
        let completion = completions.removeValue(forKey: id)
        completion?()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        // Clean up mapping if cancelled
        let key = ObjectIdentifier(utterance)
        if let id = utteranceIDs.removeValue(forKey: key) {
            _ = completions.removeValue(forKey: id)
        }
    }
}
