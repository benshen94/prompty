import Foundation

struct Storage {
    private let fileURL: URL

    init(fileURL: URL = Storage.defaultFileURL()) {
        self.fileURL = fileURL
    }

    func load() -> [PromptFolder] {
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            migrateLegacyDataIfNeeded()
        }

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return PromptFolder.sampleData()
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([PromptFolder].self, from: data)
        } catch {
            return PromptFolder.sampleData()
        }
    }

    func save(_ folders: [PromptFolder]) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(folders)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            print("Failed to save prompts: \(error)")
        }
    }

    private static func defaultFileURL() -> URL {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = appSupport.appendingPathComponent("Prompty", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("prompts.json")
    }

    private func migrateLegacyDataIfNeeded() {
        let fileManager = FileManager.default
        let legacyURL = Storage.legacyFileURL()
        guard fileManager.fileExists(atPath: legacyURL.path) else { return }
        do {
            try fileManager.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            if !fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.copyItem(at: legacyURL, to: fileURL)
            }
        } catch {
            print("Failed to migrate legacy data: \(error)")
        }
    }

    private static func legacyFileURL() -> URL {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = appSupport.appendingPathComponent("PromptBar", isDirectory: true)
        return directory.appendingPathComponent("prompts.json")
    }
}
