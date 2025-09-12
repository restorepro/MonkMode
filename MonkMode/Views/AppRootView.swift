//
//  AppRootView.swift
//  MonkMode
//
//  Created by Greg Williams on 11.09.2025.
//

import SwiftUI

// MARK: - Root App Container
struct AppRootView: View {
    @EnvironmentObject var vm: MonkViewModel
    @EnvironmentObject var themeManager: ThemeManager   // ✅ keep your theme manager
    @State private var showMusicOverlay = false
    @State private var showTimerOverlay = false

    // ⬇️ Keep selections here so they persist across sheets
    @State private var selectedCourse: String = ""
    @State private var selectedChapter: String = ""
    @State private var selectedCards: [Flashcard] = []

    var body: some View {
        NavigationStack {
            // Dashboard replaces HomeView
            DashboardPage(
                selectedCourse: $selectedCourse,
                selectedChapter: $selectedChapter,
                selectedCards: $selectedCards
            )
            .environmentObject(vm)
            .environmentObject(themeManager)   // ✅ pass down
            .overlay(floatingButtons, alignment: .bottomTrailing)
            .onAppear {
                AudioService.shared.configureSession()
            }
            .navigationTitle("MonkMode")
        }
        .sheet(isPresented: $showMusicOverlay) {
            MusicOverlayView()
                .environmentObject(themeManager)   // ✅ pass down
        }
        .sheet(isPresented: $showTimerOverlay) {
            TimerOverlayView(vm: vm)
                .environmentObject(themeManager)   // ✅ pass down
        }
        .appBackground(theme: themeManager)        // ✅ apply global background
    }

    // MARK: - Floating buttons (with animation)
    private var floatingButtons: some View {
        VStack(spacing: 16) {
            // 🎶 Music hub button
            FloatingHubButton(
                icon: AudioService.shared.isPlaying ? "pause.fill" : "music.note",
                action: { showMusicOverlay = true },
                background: AudioService.shared.isPlaying ? .green : .blue
            )
            .scaleEffect(AudioService.shared.isPlaying ? 1.2 : 1.0)
            .animation(
                AudioService.shared.isPlaying
                    ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                    : .default,
                value: AudioService.shared.isPlaying
            )

            // ⏱ Timer hub button
            FloatingHubButton(icon: "timer") {
                showTimerOverlay = true
            }
        }
        .padding()
    }
}

// MARK: - Dashboard content
private struct DashboardPage: View {
    @EnvironmentObject var vm: MonkViewModel

    // Launcher state
    @State private var pendingMode: StudyMode? = nil
    @State private var showLauncher = false
    @State private var showSession = false

    // Selections (bound from AppRootView ✅)
    @Binding var selectedCourse: String
    @Binding var selectedChapter: String
    @Binding var selectedCards: [Flashcard]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                statChips
                actionGrid
            }
            .padding(16)
        }
        // 1) Pick course/chapter in a sheet
        .sheet(isPresented: $showLauncher) {
            if let mode = pendingMode {
                SessionStartSheet(vm: vm, mode: mode) { course, chapter, cards in
                    switch mode {
                    case .treadmill:
                        print("🏃 Treadmill start → \(course) / \(chapter) (\(cards.count) cards)")
                    case .free:
                        print("📖 Free Study start → \(course) / \(chapter) (\(cards.count) cards)")
                    case .reading:
                        print("📚 Reading start → \(course) / \(chapter) (\(cards.count) cards)")
                    case .quiz:
                        print("❓ Quiz start → \(course) / \(chapter) (\(cards.count) cards)")
                    }

                    self.selectedCourse = course
                    self.selectedChapter = chapter
                    self.selectedCards = cards
                    self.showSession = true
                }
            } else {
                Text("No mode selected").padding()
            }
        }

        // 2) Launch session in another sheet
        .sheet(isPresented: $showSession) {
            if let mode = pendingMode {
//                print("🚀 Launching SessionManagerView → mode=\(mode.rawValue), cards=\(selectedCards.count), course=\(selectedCourse), chapter=\(selectedChapter)")
                SessionManagerView(
                    vm: SessionManagerVM(
                        mode: mode,
                        cards: selectedCards,
                        course: selectedCourse,
                        chapter: selectedChapter
                    )
                )
            } else {
                Text("No session available").padding()
            }
        }
    }

    // MARK: - UI: Header
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Welcome back 👋")
                .font(.title)
                .bold()
            Text("Choose a session to begin.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - UI: Stat Chips
    private var statChips: some View {
        HStack(spacing: 8) {
            chip(title: "Today", value: "\(vm.sessionsTodayMinutes)m")
            chip(title: "This Week", value: formattedMinutes(vm.sessionsWeekMinutes))
            chip(title: "Streak", value: "\(vm.sessionStreak) day\(vm.sessionStreak == 1 ? "" : "s")")
        }
    }

    private func chip(title: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.subheadline).bold().monospacedDigit()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(.secondary.opacity(0.12)))
    }

    private func formattedMinutes(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }

    // MARK: - UI: Action Grid
    private var actionGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {

            // Treadmill
            Button {
                pendingMode = .treadmill
                print("🎬 Selected mode: treadmill")
                showLauncher = true
            } label: {
                ActionCard(title: "Treadmill", icon: "figure.run")
            }

            // Regular (Free Study)
            Button {
                pendingMode = .free
                print("🎬 Selected mode: free (Regular Study)")
                showLauncher = true
            } label: {
                ActionCard(title: "Regular Study", icon: "doc.text")
            }

            // Reading
            Button {
                pendingMode = .reading
                print("🎬 Selected mode: reading")
                showLauncher = true
            } label: {
                ActionCard(title: "Reading", icon: "book")
            }

            // Quiz
            Button {
                pendingMode = .quiz
                print("🎬 Selected mode: quiz")
                showLauncher = true
            } label: {
                ActionCard(title: "Quiz", icon: "questionmark.circle")
            }
        }
    }
}

// MARK: - Session launcher sheet
private struct SessionStartSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var vm: MonkViewModel
    let mode: StudyMode

    @State private var selectedCourse: String
    @State private var selectedChapter: String

    let onStart: (_ course: String, _ chapter: String, _ cards: [Flashcard]) -> Void

    // ✅ init ensures defaults are non-empty
    init(vm: MonkViewModel, mode: StudyMode, onStart: @escaping (String, String, [Flashcard]) -> Void) {
        self.vm = vm
        self.mode = mode
        self.onStart = onStart
        let firstCourse = vm.cards.first?.course ?? ""
        let firstChapter = vm.cards.first?.chapter ?? ""
        _selectedCourse = State(initialValue: firstCourse)
        _selectedChapter = State(initialValue: firstChapter)

        print("🛠️ SessionStartSheet init → firstCourse=\(firstCourse), firstChapter=\(firstChapter), totalCards=\(vm.cards.count)")
    }

    private var courses: [String] {
        let list = Array(Set(vm.cards.compactMap { $0.course })).sorted()
        print("📚 Available courses → \(list)")
        return list
    }

    private var chapters: [String] {
        let list = Array(Set(vm.cards
            .filter { $0.course == selectedCourse }
            .compactMap { $0.chapter }))
            .sorted()
        print("📖 Chapters for course=\(selectedCourse) → \(list)")
        return list
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Mode") {
                    Text(mode.rawValue.capitalized)
                        .font(.headline)
                }

                Section("Course") {
                    Picker("Course", selection: $selectedCourse) {
                        ForEach(courses, id: \.self) { Text($0).tag($0) }
                    }
                    .onChange(of: selectedCourse) { newCourse in
                        print("🔄 Course changed → \(newCourse)")
                        if let first = vm.cards.first(where: { $0.course == newCourse })?.chapter {
                            selectedChapter = first
                            print("   ↳ Auto-selected chapter → \(first)")
                        } else {
                            print("   ⚠️ No chapters found for course=\(newCourse)")
                        }
                    }
                }

                Section("Chapter") {
                    Picker("Chapter", selection: $selectedChapter) {
                        ForEach(chapters, id: \.self) { Text($0).tag($0) }
                    }
                }
            }
            .navigationTitle("Start Session")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        print("❌ SessionStartSheet dismissed without starting")
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        print("▶️ Start tapped → course=\(selectedCourse), chapter=\(selectedChapter)")
                        let cards = vm.cards.filter {
                            $0.course == selectedCourse && $0.chapter == selectedChapter
                        }
                        print("   📦 Filtered cards count=\(cards.count)")
                        if cards.isEmpty {
                            print("   ⚠️ No cards matched course=\(selectedCourse), chapter=\(selectedChapter)")
                        } else {
                            print("   ✅ Passing cards to onStart")
                        }

                        // 🔑 Pass cards immediately, but trigger session launch on next runloop tick
                        DispatchQueue.main.async {
                            onStart(selectedCourse, selectedChapter, cards)
                        }

                        dismiss()
                    }
                    .disabled(selectedCourse.isEmpty || selectedChapter.isEmpty)
                }
            }
        }
    }
}
