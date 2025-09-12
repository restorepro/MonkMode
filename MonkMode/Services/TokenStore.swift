//
//  TokenStore.swift
//  MonkMode
//
//  Created by Greg Williams on 11.09.2025.
//

// MonkMode/Services/TokenStore.swift
import Foundation

enum TokenStore {
    // You could load this from Keychain, .plist, or env vars later
    static var huggingFace: String? {
        // Hardcode for now, replace with Keychain lookup if needed
        return "YOUR_HF_API_KEY_HERE"
    }
}
