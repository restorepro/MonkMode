//
//  UtilityTestView.swift
//  MonkMode
//
//  Created by Greg Williams on 13.09.2025.
//

import SwiftUI

// Unique log entry model to avoid duplicate IDs
struct LogEntry: Identifiable, Hashable {
    let id = UUID()
    let text: String
}

struct UtilityTestView: View {
    @EnvironmentObject var vm: MonkViewModel
    @ObservedObject private var audio = AudioService.shared

    @State private var log: [LogEntry] = []
    @State private var tracks: [String] = []
    @State private var selectedTrack: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Form {
                    // 1. Session Save Test
                    Section("1️⃣ Session Save Test") {
                        Button("Simulate Save Session") {
                            let session = StudySession(
                                mode: .free,
                                course: "Test Course",
                                chapter: "Test Chapter",
                                duration: 300,
                                score: 2,
                                date: Date()
                            )
                            SessionService.shared.addSession(session)
                            print("🟢 [UtilityTest] Saved session → \(session)")
                            appendLog("✅ Dummy StudySession saved (total: \(SessionService.shared.sessions.count))\n   → mode=\(session.mode.rawValue), course=\(session.course), chapter=\(session.chapter), duration=\(Int(session.duration))s")
                        }
                    }

                    // 2. Add Flashcard Test
                    Section("2️⃣ Add Flashcard Test") {
                        Button("Add Sample Card") {
                            let card = Flashcard(
                                id: UUID(),
                                question: "What is the capital of France?",
                                answer: "Paris",
                                course: "Geography",
                                chapter: "Capitals"
                            )
                            FlashcardService.shared.addCard(card)
                            vm.cards.append(card)

                            let json = (try? String(data: JSONEncoder.prettyPrinted.encode(card), encoding: .utf8)) ?? "{}"
                            print("🟢 [UtilityTest] Added flashcard: \(card.question)")
                            appendLog("✅ Flashcard added (Geography/Capitals)\n\(json)")
                        }
                    }

                    // 3. Bulk JSON Import
                    Section("3️⃣ Bulk JSON Test") {
                        Button("Import Dummy Bulk JSON") {
                            let json = """
                            [
                              { "question": "Largest planet?", "answer": "Jupiter" },
                              { "question": "Speed of light?", "answer": "299,792 km/s" }
                            ]
                            """
                            FlashcardService.shared.importBulkJSON(json, course: "Astronomy", chapter: "Planets")
                            appendLog("✅ Imported bulk cards into Astronomy/Planets")
                        }
                    }

                    // 4. AI Stub
                    Section("4️⃣ AI Service Test") {
                        Button("Stubbed AI Call") {
                            let fakeJSON = "[{\"question\":\"Neuron function?\",\"answer\":\"Transmit signals\"}]"
                            print("🟢 [UtilityTest] AI call stub → \(fakeJSON)")
                            appendLog("✅ AI returned stub JSON: \(fakeJSON)")
                        }
                    }

                    // 5. Audio Controls
                    Section("5️⃣ Audio Test") {
                        HStack {
                            Button(action: {
                                if audio.isPlaying {
                                    audio.pause()
                                    appendLog("⏸ Paused \(audio.currentTrack ?? "")")
                                } else if let current = audio.currentTrack {
                                    audio.resume()
                                    appendLog("▶️ Resumed \(current)")
                                } else if let first = tracks.first {
                                    selectedTrack = first
                                    audio.playSound(named: first)
                                    appendLog("▶️ Playing \(first)")
                                }
                            }) {
                                Label(audio.isPlaying ? "Pause" : "Play",
                                      systemImage: audio.isPlaying ? "pause.fill" : "play.fill")
                            }

                            if let current = audio.currentTrack, !current.isEmpty {
                                Text(current.replacingOccurrences(of: ".mp3", with: ""))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }

                    Section("Tracks") {
                        if tracks.isEmpty {
                            Text("No MP3 files found in bundle")
                                .foregroundColor(.secondary)
                        } else {
                            Picker("Select Track", selection: $selectedTrack) {
                                ForEach(tracks, id: \.self) { track in
                                    Text(track.replacingOccurrences(of: ".mp3", with: ""))
                                        .tag(track)
                                }
                            }
                            .onChange(of: selectedTrack) { newValue in
                                guard !newValue.isEmpty else { return }
                                audio.playSound(named: newValue)
                                appendLog("▶️ Playing \(newValue)")
                            }
                        }
                    }

                    Section("Volume") {
                        Slider(value: Binding(
                            get: { Double(audio.volume) },
                            set: { audio.volume = Float($0) }
                        ), in: 0...1)
                    }
                }

                Divider()

                // Feedback log viewer
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(log.reversed()) { entry in
                            Text(entry.text)
                                .font(.caption2)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding()
                }
                .frame(maxHeight: 160)
            }
            .navigationTitle("Utility Test Page")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear Log") { log.removeAll() }
                }
            }
            .onAppear {
                AudioService.shared.configureSession()
                let list = audio.availableTracks()
                self.tracks = list

                if let current = audio.currentTrack, !current.isEmpty, list.contains(current) {
                    self.selectedTrack = current
                } else if let first = list.first {
                    self.selectedTrack = first
                }
            }

        }
    }

    private func appendLog(_ entry: String) {
        let ts = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        log.append(LogEntry(text: "[\(ts)] \(entry)"))
    }

    private func formatTime(_ t: TimeInterval) -> String {
        guard t.isFinite && !t.isNaN else { return "0:00" }
        let m = Int(t) / 60
        let s = Int(t) % 60
        return String(format: "%d:%02d", m, s)
    }
}

extension JSONEncoder {
    static var prettyPrinted: JSONEncoder {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        return enc
    }
}
