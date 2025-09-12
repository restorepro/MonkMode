//
//  FloatingHubButton.swift
//  MonkMode
//
//  Created by Greg Williams on 11.09.2025.
//

import SwiftUI

struct FloatingHubButton: View {
    let icon: String
    let action: () -> Void
    var background: Color = .accentColor   // 👈 new, defaults to accent

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .padding()
                .background(background)
                .foregroundColor(.white)
                .clipShape(Circle())
                .shadow(radius: 4)
        }
    }
}
