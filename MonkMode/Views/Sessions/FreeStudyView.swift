//
//  FreeStudyView.swift
//  MonkMode
//
//  Created by Greg Williams on 12.09.2025.
//

import SwiftUI

struct FreeStudyView: View {
    @ObservedObject var vm: SessionManagerVM

    var body: some View {
        VStack(spacing: 20) {
            if vm.cards.isEmpty {
                Text("⚠️ No cards available")

            } else if vm.isFinished {
                VStack(spacing: 12) {
                    Text("🆓 Free Study Complete")
                        .font(.title.bold())
                    Text("Score: \(vm.score) / \(vm.cards.count)")
                        .font(.title2)
                }

            } else {
                let card = vm.cards[vm.currentIndex]

                VStack(spacing: 12) {
                    // Question
                    Text(card.question)
                        .font(.title)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 4)

                    // Answer if revealed
                    if vm.showingAnswer {
                        if card.variantType == .multipleChoice, let options = card.choices {
                            VStack(spacing: 8) {
                                ForEach(options, id: \.self) { choice in
                                    Text(choice)
                                        .padding(6)
                                        .frame(maxWidth: .infinity)
                                        .background(choice == card.answer
                                                    ? Color.green.opacity(0.3)
                                                    : Color.gray.opacity(0.2))
                                        .cornerRadius(8)
                                }
                            }
                            .onAppear {
                                print("✅ FreeStudy: Multiple choice shown with \(options.count) options. Correct=\(card.answer)")
                            }
                        } else {
                            Text(card.answer)
                                .font(.title2)
                                .foregroundColor(.green)
                                .onAppear {
                                    print("✅ FreeStudy: Showing answer → \(card.answer)")
                                }
                        }

                        HStack {
                            Button("👍 Correct") { vm.markCorrect() }
                                .buttonStyle(.borderedProminent)
                            Button("👎 Missed") { vm.markIncorrect() }
                                .buttonStyle(.bordered)
                        }
                    }

                    Spacer()

                    // Reveal / Next button
                    Button(vm.showingAnswer ? "➡️ Next" : "👁️ Reveal Answer") {
                        if vm.showingAnswer {
                            print("➡️ FreeStudy: Next card tapped at index \(vm.currentIndex)")
                            vm.nextCard()
                        } else {
                            print("👁️ FreeStudy: Reveal tapped at index \(vm.currentIndex)")
                            vm.showingAnswer = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
        .navigationTitle("Free Study")
    }
}
