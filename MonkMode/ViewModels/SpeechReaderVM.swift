import Foundation
import AVFoundation

final class SpeechReaderVM: NSObject, ObservableObject {
    @Published var sentences: [String] = []
    @Published var currentSentenceIndex: Int? = nil

    private let synthesizer = AVSpeechSynthesizer()
    private var currentIndex: Int = 0

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func load(text: String) {
        sentences = text
            .components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        currentIndex = 0
        print("📖 Loaded \(sentences.count) sentences:")
        for (i, s) in sentences.enumerated() {
            print("   [\(i)] \(s)")
        }
    }

    func start() {
        guard !sentences.isEmpty else { return }
        currentIndex = 0
        speakCurrent()
    }

    func pause() {
        synthesizer.pauseSpeaking(at: .word)
    }

    func resume() {
        synthesizer.continueSpeaking()
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        currentIndex = 0
        currentSentenceIndex = nil
    }

    private func speakCurrent() {
        guard currentIndex < sentences.count else {
            print("🏁 Finished all sentences")
            currentSentenceIndex = nil
            return
        }

        let sentence = sentences[currentIndex]
        let utterance = AVSpeechUtterance(string: sentence)
        utterance.voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.siri_nicky_en-US_compact")
        utterance.rate = 0.4

        synthesizer.speak(utterance)

        currentSentenceIndex = currentIndex
        let ts = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        print("🕒 [\(ts)] Speaking [\(currentIndex)]: \(sentence)")
    }
}

// MARK: - Delegate
extension SpeechReaderVM: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didFinish utterance: AVSpeechUtterance) {
        print("✅ Finished sentence [\(currentIndex)]")
        currentIndex += 1
        speakCurrent()   // 👈 queue the next one after finishing
    }
}
