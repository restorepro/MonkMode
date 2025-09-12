//
//  FreeStudyView.swift
//  MonkMode
//
//  Created by Greg Williams on 12.09.2025.
//

import SwiftUI

struct FreeStudyView: View {
    @ObservedObject var vm: SessionManagerVM

    @State private var showAnswer = false

    var body: some View {
        VStack(spacing: 24) {
            if vm.currentIndex < vm.cards.count {
                let card = vm.cards[vm.currentIndex]

                Text(card.question)
                    .font(.title2)
                    .multilineTextAlignment(.center)

                if showAnswer {
                    Text(card.answer)
                        .font(.title3)
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }

                HStack {
                    Button(showAnswer ? "Hide Answer" : "Show Answer") {
                        showAnswer.toggle()
                    }
                    Button("Read Aloud") { vm.readCurrentCard() }
                }

                Button("Next") { vm.nextCard() }
                    .buttonStyle(.borderedProminent)
            } else {
                Text("All done ✅").font(.headline)
            }
        }
        .padding()
    }
}
