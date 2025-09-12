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

    var body: some View {
        NavigationStack {
            // Replaces HomeView with an in-file dashboard so we can add stat chips + session buttons
            DashboardPage()
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

    // MARK: - Original floating buttons (unchanged behavior, with animation)
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

// MARK: - Dashboard content (kept inside this file to avoid renaming your existing HomeView)
private struct DashboardPage: View {
    @EnvironmentObject var vm: MonkViewModel

    // Launcher state for starting a session after picking course/chapter
    @State private var pendingMode: StudyMode? = nil
    @State private var showLauncher = false
    @State private var showSession = false
    @State private var selectedCards: [Flashcard] = []

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
                SessionStartSheet(vm: vm, mode: mode) { _, _, cards in
                    self.selectedCards = cards
                    self.showSession = true
                }
            } else {
                Text("No mode selected").padding()
            }
        }
        // 2) Start the session after selection
        .sheet(isPresented: $showSession) {
            if let mode = pendingMode {
                SessionManagerView(vm: SessionManagerVM(mode: mode, cards: selectedCards))
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

    // MARK: - UI: Stat Chips (uses your MonkViewModel helpers)
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

    // MARK: - UI: Action Grid (session buttons + logs/progress)
    private var actionGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {

            // Treadmill
            Button {
                pendingMode = .treadmill
                showLauncher = true
            } label: {
                ActionCard(title: "Treadmill", icon: "figsure.run")
            }

            // Regular (Free Study)
            Button {
                pendingMode = .free
                showLauncher = true
            } label: {
                ActionCard(title: "Regular Study", icon: "doc.text")
            }

            // Reading
            Button {
                pendingMode = .reading
                showLauncher = true
            } label: {
                ActionCard(title: "Reading", icon: "book")
            }

            // Quiz
            Button {
                pendingMode = .quiz
                showLauncher = true
            } label: {
                ActionCard(title: "Quiz", icon: "questionmark.circle")
            }

//            // Session Logs (assumes you have this screen; if it’s named differently, change here)
//            NavigationLink {
//                SessionsLogView()
//            } label: {
//                ActionCard(title: "Session Logs", icon: "clock.arrow.circlepath")
//            }
//
//            // Progress (assumes you have this screen; if it’s named differently, change here)
//            NavigationLink {
//                ProgressViewScreen()
//            } label: {
//                ActionCard(title: "Progress", icon: "chart.bar")
//            }
        }
    }
}

// MARK: - Session launcher sheet (Course + Chapter picker)
private struct SessionStartSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var vm: MonkViewModel
    let mode: StudyMode

    @State private var selectedCourse: String = ""
    @State private var selectedChapter: String = ""

    let onStart: (_ course: String, _ chapter: String, _ cards: [Flashcard]) -> Void

    private var courses: [String] {
        Array(Set(vm.cards.compactMap { $0.course })).sorted()
    }
    private var chapters: [String] {
        Array(Set(vm.cards
            .filter { $0.course == selectedCourse }
            .compactMap { $0.chapter }))
            .sorted()
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
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        let cards = vm.cards.filter {
                            $0.course == selectedCourse && $0.chapter == selectedChapter
                        }
                        onStart(selectedCourse, selectedChapter, cards)
                        dismiss()
                    }
                    .disabled(selectedCourse.isEmpty || selectedChapter.isEmpty)
                }
            }
        }
    }
}
