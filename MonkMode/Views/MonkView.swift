//
//  MonkView.swift
//  MonkMode
//
//  Created by Greg Williams on 11.09.2025.
//

import SwiftUI

struct MonkView: View {
    @StateObject var vm = MonkViewModel()
    @State private var showSettings = false

    var body: some View {
        VStack {
            if vm.currentIndex < vm.cards.count {
                Text(vm.cards[vm.currentIndex].question)
                    .font(.title)
                    .padding()
            } else {
                Text("Session Complete 🎉")
            }
        }
        .navigationTitle("Monk Mode")
        .toolbar {
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gear")
            }
        }
        .sheet(isPresented: $showSettings) {
            MonkSettingsView(vm: vm)
        }
    }
}
