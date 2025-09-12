//
//  AppGradients.swift
//  MonkMode
//
//  Created by Greg Williams on 12.09.2025.
//

import SwiftUI

struct AppGradients {
    static var purpleBlue: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.purple.opacity(0.9),
                Color.blue.opacity(0.8)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
