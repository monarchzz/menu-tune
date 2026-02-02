import AppKit
import Foundation

final class ArtworkCache {
    static let shared = ArtworkCache()
    private init() {}

    private let memoryCache = NSCache<NSString, NSImage>()
    private let fileManager = FileManager.default

    private lazy var baseURL: URL = {
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let dir = caches.appendingPathComponent(
            "com.hieunt0220.MenuTune/artwork", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }()

    private func path(forKey key: String) -> URL {
        baseURL.appendingPathComponent(key)
    }

    private func data(for key: String) async -> Data? {
        let url = path(forKey: key)
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        return try? Data(contentsOf: url)
    }

    func save(data: Data, for key: String) async throws {
        let url = path(forKey: key)
        // write atomically
        let tmp = url.appendingPathExtension("tmp")
        try data.write(to: tmp, options: .atomic)
        try? fileManager.removeItem(at: url)
        try fileManager.moveItem(at: tmp, to: url)
    }

    func image(for key: String?) async -> NSImage? {
        guard let key else { return nil }
        if let cached = memoryCache.object(forKey: key as NSString) { return cached }
        let data = await data(for: key)
        guard let data else { return nil }
        // Create NSImage on MainActor
        return await MainActor.run {
            if let img = NSImage(data: data) {
                memoryCache.setObject(img, forKey: key as NSString, cost: data.count)
                return img
            }
            return nil
        }
    }
}
