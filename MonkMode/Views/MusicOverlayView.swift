//
//  MusicOverlayView.swift
//  MonkMode
//
//  Created by Greg Williams on 12.09.2025.
//

import SwiftUI

struct MusicOverlayView: View {
    @ObservedObject var audio = AudioService.shared
    @Environment(\.dismiss) var dismiss

    @State private var tracks: [String] = []
    @State private var selectedTrack: String = ""

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Playback Controls
                Section("Playback") {
                    HStack {
                        Button(action: {
                            if audio.isPlaying {
                                audio.pause()
                            } else if let current = audio.currentTrack {
                                audio.resume()
                            } else if let first = tracks.first {
                                selectedTrack = first
                                audio.playSound(named: first)
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

                // MARK: Track Picker
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
                        }
                    }
                }

                // MARK: Volume
                Section("Volume") {
                    Slider(value: Binding(
                        get: { Double(audio.volume) },
                        set: { audio.volume = Float($0) }
                    ), in: 0...1)
                }

                // MARK: Progress / Scrubber
                if audio.duration > 0 {
                    Section("Progress") {
                        VStack {
                            Slider(value: Binding(
                                get: { audio.currentTime },
                                set: { audio.seek(to: $0) }
                            ), in: 0...audio.duration)

                            HStack {
                                Text(formatTime(audio.currentTime))
                                Spacer()
                                Text(formatTime(audio.duration))
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Background Music")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
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

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
