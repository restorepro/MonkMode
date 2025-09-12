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
            FloatingHubButton(icon: "music.note") {
                showMusicOverlay = true
            }
            FloatingHubButton(icon: "timer") {
                showTimerOverlay = true
            }
        }
        .padding()
    }
}
