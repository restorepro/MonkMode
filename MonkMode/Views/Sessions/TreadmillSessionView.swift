//
//  TreadmillSessionView.swift
//  MonkMode
//
//  Created by Greg Williams on 12.09.2025.
//

import SwiftUI

struct TreadmillSessionView: View {
    @ObservedObject var vm: SessionManagerVM

    var body: some View {
        VStack {
            if vm.currentIndex < vm.cards.count {
                Text(vm.cards[vm.currentIndex].question)
                    .font(.title)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            Spacer()
            Button("Next") { vm.nextCard() }
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
