//
//  TTSService.swift
//  MonkMode
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

    // The one shared synthesizer
    private let synth = AVSpeechSynthesizer()

    // Forward delegate so other layers (e.g. SpeechReaderViewModel) can observe
    weak var forwardDelegate: AVSpeechSynthesizerDelegate?

    // Expose the synthesizer read-only for checks like isSpeaking/isPaused
    var speechSynth: AVSpeechSynthesizer { synth }

    // Map utterance -> id and completion
    private var utteranceIDs: [ObjectIdentifier: UUID] = [:]
    private var completions: [UUID: () -> Void] = [:]

    // Convenience: speak raw text with optional completion (existing API)
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
            // Fallback voice (simulator/device safe)
            utt.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        let key = ObjectIdentifier(utt)
        utteranceIDs[key] = id
        if let onFinish { completions[id] = onFinish }
        synth.speak(utt)
        return id
    }

    // NEW: Speak a pre-configured utterance (used by SpeechReaderViewModel)
    func speak(utterance: AVSpeechUtterance) {
        synth.speak(utterance)
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
        if let id = utteranceIDs.removeValue(forKey: key) {
            let completion = completions.removeValue(forKey: id)
            completion?()
        }
        forwardDelegate?.speechSynthesizer?(synthesizer, didFinish: utterance)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        let key = ObjectIdentifier(utterance)
        if let id = utteranceIDs.removeValue(forKey: key) {
            _ = completions.removeValue(forKey: id)
        }
        forwardDelegate?.speechSynthesizer?(synthesizer, didCancel: utterance)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           willSpeakRangeOfSpeechString characterRange: NSRange,
                           utterance: AVSpeechUtterance) {
        forwardDelegate?.speechSynthesizer?(synthesizer,
                                            willSpeakRangeOfSpeechString: characterRange,
                                            utterance: utterance)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        forwardDelegate?.speechSynthesizer?(synthesizer, didPause: utterance)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        forwardDelegate?.speechSynthesizer?(synthesizer, didContinue: utterance)
    }
}
