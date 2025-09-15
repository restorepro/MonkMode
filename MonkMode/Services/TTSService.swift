//
//  TTSService.swift
//  MonkMode
//

import AVFoundation

final class TTSService: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = TTSService()

    private override init() {
        super.init()
        synth.delegate = self
    }

    // MARK: - Synth
    private let synth = AVSpeechSynthesizer()
    var speechSynth: AVSpeechSynthesizer { synth }   // read-only access

    // MARK: - Simple API
    func speak(text: String,
               voiceId: String? = nil,
               rate: Float = AVSpeechUtteranceDefaultSpeechRate,
               pitch: Float = 1.0,
               volume: Float = 1.0) {
        let utt = AVSpeechUtterance(string: text)
        utt.rate = rate
        utt.pitchMultiplier = pitch
        utt.volume = volume

        if let voiceId, let v = AVSpeechSynthesisVoice(identifier: voiceId) {
            utt.voice = v
        } else {
            utt.voice = AVSpeechSynthesisVoice(language: "en-US")
        }

        synth.speak(utt)
    }

    func speak(utterance: AVSpeechUtterance) {
        synth.speak(utterance)
    }

    func pause() { synth.pauseSpeaking(at: .immediate) }
    func resume() { synth.continueSpeaking() }
    func stop() { synth.stopSpeaking(at: .immediate) }

    var isSpeaking: Bool { synth.isSpeaking }
}
