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
                    .onAppear { print("⚠️ MonkView: vm.cards is empty") }

            } else if vm.isFinished {
                VStack(spacing: 12) {
                    Text("🧘 Monk Session Complete")
                        .font(.title.bold())
                    Text("Score: \(vm.score) / \(vm.cards.count)")
                        .font(.title2)
                }
                .onAppear {
                    print("✅ MonkView: Session finished, score=\(vm.score)/\(vm.cards.count)")
                }

            } else if vm.currentIndex < vm.cards.count {
                let card = vm.cards[vm.currentIndex]

                VStack(spacing: 12) {
                    // Question
                    Text(card.question)
                        .font(.title)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 4)
                        .onAppear {
                            print("🃏 MonkView: Showing card \(vm.currentIndex + 1)/\(vm.cards.count) – \(card.question)")
                            if let type = card.variantType {
                                print("🧩 Variant type=\(type.rawValue) at index \(vm.currentIndex)")
                            } else {
                                print("🧩 Variant type=base at index \(vm.currentIndex)")
                            }
                        }

                    // 🆕 Show variant type label
                    if let type = card.variantType {
                        Text("🧩 \(type.rawValue.capitalized) Variant")
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else {
                        Text("🧩 Base Card")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    // Answer (only if showing)
                    // Answer / Choices depending on variant
                    if card.variantType == .multipleChoice, let options = card.choices {
                        VStack(spacing: 8) {
                            ForEach(options, id: \.self) { choice in
                                Text(choice)
                                    .padding(6)
                                    .frame(maxWidth: .infinity)
                                    .background(choice == card.answer && vm.showingAnswer
                                                ? Color.green.opacity(0.3)
                                                : Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                        .onAppear {
                            print("✅ MonkView: Showing multiple choice with \(options.count) options. Correct answer = \(card.answer)")
                        }

                        if vm.showingAnswer {
                            HStack {
                                Button("👍 Correct") {
                                    print("👉 Correct tapped on index \(vm.currentIndex)")
                                    vm.markCorrect()
                                }
                                .buttonStyle(.borderedProminent)

                                Button("👎 Missed") {
                                    print("👉 Missed tapped on index \(vm.currentIndex)")
                                    vm.markIncorrect()
                                }
                                .buttonStyle(.bordered)
                            }
                        }

                    } else if vm.showingAnswer {
                        Text(card.answer)
                            .font(.title2)
                            .foregroundColor(.green)
                            .padding(.bottom, 4)
                            .onAppear { print("✅ MonkView: Showing answer → \(card.answer)") }

                        HStack {
                            Button("👍 Correct") {
                                print("👉 Correct tapped on index \(vm.currentIndex)")
                                vm.markCorrect()
                            }
                            .buttonStyle(.borderedProminent)

                            Button("👎 Missed") {
                                print("👉 Missed tapped on index \(vm.currentIndex)")
                                vm.markIncorrect()
                            }
                            .buttonStyle(.bordered)
                        }

                    } else {
                        Text("") // placeholder to keep a View
                            .onAppear { print("❓ MonkView: Waiting for answer reveal at index \(vm.currentIndex)") }
                    }


                    // Subtle flow label
                    if let meta = card.flowMeta {
                        switch meta {
                        case .vertical:
                            Text("↓ Vertical")
                                .font(.caption2.italic())
                                .foregroundColor(.gray.opacity(0.5))
                                .onAppear { print("↕️ Flow: vertical at index \(vm.currentIndex)") }
                        case .lateral(let current, let total):
                            Text("Lateral Cluster → \(current)/\(total)")
                                .font(.caption2.italic())
                                .foregroundColor(.gray.opacity(0.5))
                                .onAppear { print("➡️ Flow: lateral cluster \(current)/\(total) at index \(vm.currentIndex)") }
                        }
                    } else {
                        Text("")
                            .onAppear { print("ℹ️ No flowMeta for card at index \(vm.currentIndex)") }
                    }

                    // Timer
                    Text("⏱ \(vm.timeRemaining)s")
                        .font(.headline)
                        .padding(.top, 6)

                    // Debug controls
                    #if DEBUG
                    HStack {
                        Button("➡️ Next (debug)") {
                            print("🔜 DebugNext tapped at index \(vm.currentIndex)")
                            vm.debugNextCard()
                        }
                        .buttonStyle(.bordered)

                        Button("👁️ Toggle Answer (debug)") {
                            print("👁️ DebugToggleAnswer tapped at index \(vm.currentIndex)")
                            vm.debugToggleAnswer()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.top, 8)
                    #endif
                }
            } else {
                Text("⚠️ Index out of range")
                    .onAppear { print("⚠️ MonkView: currentIndex \(vm.currentIndex) is out of range for cards.count \(vm.cards.count)") }
            }
        }
        .navigationTitle("Monk Mode")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button {
                showSettings = true
                print("⚙️ Settings opened")
            } label: {
                Image(systemName: "gear")
            }
        }
        .sheet(isPresented: $showSettings) { settingsSheet }
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
                    Button("Done") {
                        print("⚙️ Settings closed")
                        showSettings = false
                    }
                }
            }
        }
    }
}
