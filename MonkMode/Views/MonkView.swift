//
//  MonkView.swift
//  MonkMode
//
//  Created by Greg Williams on 11.09.2025.
//
import SwiftUI

struct MonkView: View {
    @StateObject var vm: MonkViewModel
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 20) {
            if vm.cards.isEmpty {
                Text("⚠️ No cards available")
                    .font(.headline)
                    .foregroundColor(.secondary)

            } else if vm.isFinished {
                VStack(spacing: 12) {
                    Text("🧘 Monk Session Complete")
                        .font(.title.bold())
                    Text("Score: \(vm.score) / \(vm.cards.count)")
                        .font(.title2)
                }

            } else if vm.currentIndex < vm.cards.count {
                let card = vm.cards[vm.currentIndex]

                VStack(spacing: 16) {
                    Text(card.question)
                        .font(.title)
                        .multilineTextAlignment(.center)
                        .padding()

                    if vm.showingAnswer {
                        Text(card.answer)
                            .font(.title2)
                            .foregroundColor(.green)
                            .padding()

                        HStack {
                            Button("👍 Correct") { vm.markCorrect() }
                                .buttonStyle(.borderedProminent)
                            Button("👎 Missed") { vm.markIncorrect() }
                                .buttonStyle(.bordered)
                        }
                    }

                    Text("⏱ \(vm.timeRemaining)s")
                        .font(.headline)
                        .padding(.top)
                }
            }
        }
        .navigationTitle("Monk Mode")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gear")
            }
        }
        .sheet(isPresented: $showSettings) {
            settingsSheet
        }
    }

    // Inline settings panel
    private var settingsSheet: some View {
        NavigationStack {
            Form {
                Section("Timing") {
                    Stepper("Question Time: 5s", value: .constant(5), in: 3...20)
                    Stepper("Answer Time: 5s", value: .constant(5), in: 3...20)
                }

                Section("Options") {
                    Toggle("Shuffle Cards", isOn: .constant(false))
                    Toggle("Auto-Save Sessions", isOn: .constant(true))
                }
            }
            .navigationTitle("Monk Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showSettings = false }
                }
            }
        }
    }
}
