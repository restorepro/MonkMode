//
//  AppRootView.swift
//  MonkMode
//
//  Created by Greg Williams on 11.09.2025.
//

import SwiftUI

struct AppRootView: View {
    @EnvironmentObject var vm: MonkViewModel
    @EnvironmentObject var themeManager: ThemeManager   // ✅ add theme manager
    @State private var showMusicOverlay = false
    @State private var showTimerOverlay = false

    var body: some View {
        NavigationStack {
            HomeView()
                .environmentObject(vm)
                .environmentObject(themeManager)   // ✅ pass down
                .overlay(floatingButtons, alignment: .bottomTrailing)
                .onAppear {
                    AudioService.shared.configureSession()
                }

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
