//
//  AppRootView.swift
//  MonkMode
//
//  Created by Greg Williams on 11.09.2025.
//

import SwiftUI

struct AppRootView: View {
    @EnvironmentObject var vm: MonkViewModel
    @State private var showMusicOverlay = false
    @State private var showTimerOverlay = false

    var body: some View {
        NavigationStack {
            HomeView()
                .environmentObject(vm)
                .overlay(floatingButtons, alignment: .bottomTrailing)
        }
        .sheet(isPresented: $showMusicOverlay) {
            MusicOverlayView()
        }
        .sheet(isPresented: $showTimerOverlay) {
            TimerOverlayView(vm: vm)   // pass VM for live session data
        }
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
