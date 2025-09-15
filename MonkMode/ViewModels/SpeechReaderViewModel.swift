//  SpeechReaderViewModel.swift
//  MonkMode (adapted from your other project)

import Foundation
import AVFoundation

struct IndexedUtterance {
    let utterance: AVSpeechUtterance
    let sentenceIndex: Int
}

final class SpeechReaderViewModel: NSObject, ObservableObject {
    // MARK: - Published UI state
    @Published var sentences: [String] = []
    @Published var currentSentenceIndex: Int? = nil
    @Published var currentSentenceIndexRegular: Int?
    @Published var currentSentenceIndexParagraph: Int?

    @Published var isSpeaking: Bool = false
    @Published var fullTextPreview: String = ""
    @Published var selectedVoiceIdentifier: String = "com.apple.ttsbundle.siri_nicky_en-US_compact"

    let availableVoices: [(name: String, id: String)] = [
        ("Nicky (US)", "com.apple.ttsbundle.siri_nicky_en-US_compact"),
        ("Karen (US)", "com.apple.ttsbundle.siri_karen_en-US_compact"),
        ("Gordon (US)", "com.apple.ttsbundle.siri_gordon_en-US_compact"),
        ("Arthur (US)", "com.apple.ttsbundle.siri_arthur_en-US_compact")
    ]

    @Published var paragraphMode: Bool = false

    // MARK: - Settings
    var voice: AVSpeechSynthesisVoice { validVoice(for: selectedVoiceIdentifier) }
    var rate: Float = 0.35
    var pitchMultiplier: Float = 1.0
    var volume: Float = 1.0
    var postSentenceDelay: TimeInterval = 0.6
    var shouldMixWithOtherAudio: Bool = true

    var pauseBase: TimeInterval = 1.0
    var pausePerWord: TimeInterval = 0.06
    var pauseMin: TimeInterval = 1.0
    var pauseMax: TimeInterval = 4.50

    // MARK: - Internal state
    private let synthesizer = AVSpeechSynthesizer()
    private var sentenceRanges: [NSRange] = []
    var sentenceRangesPublic: [NSRange] { sentenceRanges }
    private var fullText: String = ""
    private var utteranceQueue: [IndexedUtterance] = []
    private var binauralPlayer: AVAudioPlayer?
    @Published var lastHighlightedIndex: Int? = nil

    // ======== Session flags ========
    @Published var sessionStartTime: Date? = nil
    @Published var sessionEndTime: Date? = nil
    @Published var sessionActive: Bool = false
    @Published var hasLoggedThisSession: Bool = false
    @Published var readingCourseForLog: String? = nil
    @Published var readingChapterForLog: String? = nil

    // ======== Background music (disabled here) ========
    @Published var musicEnabled: Bool = false
    @Published var musicVolume: Float = 0.20
    @Published var duckMusicDuringSpeech: Bool = false
    private var preDuckVolume: Float = 0.20
    private let duckedVolume: Float = 0.07
    @Published var availableSongs: [String] = []

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    // MARK: - Load text
    func load(text: String) {
        stop()
        fullText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        fullTextPreview = fullText
        buildSentencesAndRanges(from: fullText)
    }

    func setDefaultVoice(to identifier: String) {
        if AVSpeechSynthesisVoice.speechVoices().contains(where: { $0.identifier == identifier }) {
            selectedVoiceIdentifier = identifier
        } else if let first = AVSpeechSynthesisVoice.speechVoices().first {
            selectedVoiceIdentifier = first.identifier
        }
    }

    func validVoice(for identifier: String) -> AVSpeechSynthesisVoice {
        if let voice = AVSpeechSynthesisVoice(identifier: identifier) {
            return voice
        }
        return AVSpeechSynthesisVoice(language: "en-US")!
    }

    func restartWithNewVoice() {
        synthesizer.stopSpeaking(at: .immediate)
        let resumeIndex = currentSentenceIndex ?? lastHighlightedIndex ?? 0
        currentSentenceIndex = resumeIndex
        start()
    }

    // MARK: - Sentence splitting
    private func buildSentencesAndRanges(from text: String) {
        sentences.removeAll()
        sentenceRanges.removeAll()
        guard !text.isEmpty else { return }

        let nsstr = text as NSString
        let tagger = NSLinguisticTagger(tagSchemes: [.lexicalClass], options: 0)
        tagger.string = text

        tagger.enumerateTags(in: NSRange(location: 0, length: nsstr.length),
                             unit: .sentence,
                             scheme: .lexicalClass,
                             options: []) { _, tokenRange, _ in
            let s = nsstr.substring(with: tokenRange).trimmingCharacters(in: .whitespacesAndNewlines)
            if !s.isEmpty {
                sentences.append(s)
                sentenceRanges.append(tokenRange)
            }
        }

        if sentences.isEmpty {
            let pieces = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            var offset = 0
            for p in pieces {
                let foundRange = (text as NSString).range(of: p, options: [], range: NSRange(location: offset, length: (text as NSString).length - offset))
                if foundRange.location != NSNotFound {
                    sentences.append(p)
                    sentenceRanges.append(foundRange)
                    offset = foundRange.location + foundRange.length
                }
            }
        }
    }

    private func sentenceIndexContaining(range: NSRange) -> Int? {
        for (i, r) in sentenceRanges.enumerated() {
            if NSIntersectionRange(r, range).length > 0 { return i }
        }
        if let last = sentenceRanges.last, range.location >= last.location { return sentences.count - 1 }
        return nil
    }
    

    func testSpeech() {
        let synthesizer = AVSpeechSynthesizer()
        let utterance = AVSpeechUtterance(string: "Hello from Monk Mode. This is a test of the speech system.")
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.4
        synthesizer.speak(utterance)
        print("🗣 testSpeech() triggered")
    }


    // MARK: - Speech controls
    func start() {
        testSpeech()
        // prevent double enqueue
        if synthesizer.isSpeaking || !utteranceQueue.isEmpty {
            print("⏭ start() ignored — already speaking or queue not empty")
            return
        }

        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
            DispatchQueue.main.async { self.isSpeaking = true }
            return
        }

        let startIndex = currentSentenceIndex ?? 0
        guard startIndex < sentences.count else { return }
        print("▶️ Starting speech with voice: \(selectedVoiceIdentifier)")

        // build the queue once
        utteranceQueue.removeAll()
        for idx in startIndex..<sentences.count {
            let u = AVSpeechUtterance(string: sentences[idx])
            u.voice = AVSpeechSynthesisVoice(identifier: selectedVoiceIdentifier)
                ?? AVSpeechSynthesisVoice(language: "en-US")
            u.rate = rate
            u.pitchMultiplier = pitchMultiplier
            u.volume = volume
            let wordCount = max(1, sentences[idx].split(whereSeparator: \.isWhitespace).count)
            let pause = min(pauseMax, max(pauseMin, pauseBase + pausePerWord * Double(wordCount)))
            u.postUtteranceDelay = pause
            u.accessibilityHint = String(idx)
            utteranceQueue.append(IndexedUtterance(utterance: u, sentenceIndex: idx))
        }

        speakNextInQueue()
    }


    private func speakNextInQueue() {
        guard !utteranceQueue.isEmpty else {
            DispatchQueue.main.async {
                self.isSpeaking = false
                self.currentSentenceIndex = nil
            }
            return
        }

        let next = utteranceQueue.removeFirst()
        synthesizer.speak(next.utterance)
        DispatchQueue.main.async {
            self.isSpeaking = true
            if !self.paragraphMode {
                self.currentSentenceIndex = next.sentenceIndex
            }
        }
    }

    func pause() {
        if synthesizer.isSpeaking {
            synthesizer.pauseSpeaking(at: .word)
            DispatchQueue.main.async { self.isSpeaking = false }
        }
    }

    func resume() {
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
            DispatchQueue.main.async { self.isSpeaking = true }
            return
        }
        if !synthesizer.isSpeaking {
            start()
        }
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.currentSentenceIndex = nil
        }
        utteranceQueue.removeAll()
    }

    // Stubbed out references from other project:
    /*
    func startBackgroundMusicUsingAudioService(selectedSong: String) { }
    func stopBackgroundMusicUsingAudioService() { }
    func setMusicVolume(_ vol: Float) { }
    func refreshAvailableSongs() { }
    func startSpeechReaderSession(course: String? = nil, chapter: String? = nil) { }
    @MainActor func stopSpeechReaderSession(
        flashcardVM: FlashcardViewModel,
        courseForLog: String? = nil,
        chapterForLog: String? = nil,
        source: String = "unknown"
    ) -> Bool { return false }
    */
}

// MARK: - AVSpeechSynthesizerDelegate
extension SpeechReaderViewModel: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.utteranceQueue.isEmpty {
                self.isSpeaking = false
                self.currentSentenceIndex = nil
            } else {
                self.speakNextInQueue()
            }
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           willSpeakRangeOfSpeechString characterRange: NSRange,
                           utterance: AVSpeechUtterance) {
        if let hint = utterance.accessibilityHint, let idx = Int(hint) {
            DispatchQueue.main.async {
                self.currentSentenceIndex = idx
                self.lastHighlightedIndex = idx
            }
        } else if let idx = sentenceIndexContaining(range: characterRange) {
            DispatchQueue.main.async {
                self.currentSentenceIndex = idx
                self.lastHighlightedIndex = idx
            }
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didStart utterance: AVSpeechUtterance) { }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didPause utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = false }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didContinue utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = true }
    }
}
