//
//  FileService.swift
//  MonkMode
//
//  Created by Greg Williams on 11.09.2025.
//

import Foundation

final class FileService {
    static let shared = FileService()
    private init() {}

    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    func save<T: Encodable>(_ object: T, to file: String) {
        let url = documentsURL.appendingPathComponent(file)
        do {
            let data = try JSONEncoder().encode(object)
            try data.write(to: url)
        } catch {
            print("❌ Save error: \(error)")
        }
    }

    func load<T: Decodable>(_ type: T.Type, from file: String) -> T? {
        let url = documentsURL.appendingPathComponent(file)
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("⚠️ Load error: \(error)")
            return nil
        }
    }
    func loadFromBundle<T: Decodable>(_ type: T.Type, filename: String) -> T? {
        guard let url = Bundle.main.url(forResource: filename, withExtension: nil) else {
            print("⚠️ Could not find \(filename) in bundle")
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("❌ Failed to decode \(filename): \(error)")
            return nil
        }
    }

}
