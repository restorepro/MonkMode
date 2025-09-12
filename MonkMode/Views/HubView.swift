//
//  HubView.swift
//  MonkMode
//
//  Created by Greg Williams on 12.09.2025.
//

import SwiftUI

struct HubView: View {
    @EnvironmentObject var vm: MonkViewModel
    @State private var selectedMode: StudyMode = .treadmill
    @State private var selectedCourse: String = ""
    @State private var selectedChapter: String = ""
    @State private var showSession = false

    var body: some View {
        NavigationStack {
            Form {
                // Mode
                Section("Study Mode") {
                    Picker("Mode", selection: $selectedMode) {
                        ForEach(StudyMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue.capitalized).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Course
                Section("Course") {
                    Picker("Course", selection: $selectedCourse) {
                        ForEach(vm.courses, id: \.self) { Text($0).tag($0) }
                    }
                }

                // Chapter
                Section("Chapter") {
                    Picker("Chapter", selection: $selectedChapter) {
                        ForEach(vm.chapters(for: selectedCourse), id: \.self) { Text($0).tag($0) }
                    }
                }

                // Start button
                Section {
                    Button("Start Session") {
                        showSession = true
                    }
                    .disabled(selectedCourse.isEmpty || selectedChapter.isEmpty)
                }
            }
            .navigationTitle("🧘 MonkMode")
            .sheet(isPresented: $showSession) {
                if let cards = vm.cardsFor(course: selectedCourse, chapter: selectedChapter) {
                    SessionManagerView(
                        vm: SessionManagerVM(
                            mode: selectedMode,
                            cards: cards
                        )
                    )
                } else {
                    Text("No cards found for this selection.")
                        .padding()
                }
            }
        }
    }
}

import Foundation

extension MonkViewModel {
    var courses: [String] {
        Array(Set(cards.compactMap { $0.course })).sorted()
    }

    func chapters(for course: String) -> [String] {
        Array(Set(cards.filter { $0.course == course }.compactMap { $0.chapter })).sorted()
    }

    func cardsFor(course: String, chapter: String) -> [Flashcard]? {
        let filtered = cards.filter { $0.course == course && $0.chapter == chapter }
        return filtered.isEmpty ? nil : filtered
    }
}

