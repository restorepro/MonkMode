//
//  HomeView.swift
//  MonkMode
//
//  Created by Greg Williams on 11.09.2025.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var vm: MonkViewModel
    @EnvironmentObject var themeManager: ThemeManager   // ✅ add theme manager
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    actionGrid
                }
                .padding(16)
            }
            .navigationTitle("Home")
            .toolbar {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gear")
                }
            }
            .sheet(isPresented: $showSettings) {
                MonkSettingsView(vm: vm)
                    .environmentObject(themeManager)   // ✅ pass theme manager down
            }
        }
        .appBackground(theme: themeManager)   // ✅ apply background globally
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Welcome back 👋")
                .font(.title)
                .bold()
            Text("Choose a mode to get started.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var actionGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            NavigationLink {
                MonkView(vm: vm)
            } label: {
                ActionCard(title: "🧘 Monk Mode", icon: "person.sitting")
            }
        }
    }
}
