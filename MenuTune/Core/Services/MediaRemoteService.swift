//
//  MediaRemoteService.swift
//  MenuTune
//
//  Fetches artwork via a bundled Swift script run by /usr/bin/swift.
//

import Foundation

// MARK: - MediaRemote Service

@MainActor
final class MediaRemoteService {

    // MARK: - Singleton

    static let shared = MediaRemoteService()

    // MARK: - Private Properties

    /// Cached script URL (looked up once at init)
    private let scriptURL: URL?

    // MARK: - Initialization

    private init() {
        self.scriptURL = Bundle.main.url(forResource: "artwork-fetcher", withExtension: nil)
        if scriptURL == nil {
            Log.error("artwork-fetcher not found in bundle", category: .services)
        }
    }

    // MARK: - Public API

    /// Fetches artwork data from the currently playing media.
    /// - Returns: Artwork data if available, nil otherwise.
    func fetchArtworkData() async -> Data? {
        guard let scriptURL else { return nil }

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
                process.arguments = [scriptURL.path]

                let pipe = Pipe()
                let errorPipe = Pipe()
                process.standardOutput = pipe
                process.standardError = errorPipe

                do {
                    try process.run()

                    // Read before waitUntilExit to avoid deadlock on large output
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

                    process.waitUntilExit()

                    if !errorData.isEmpty,
                        let errorString = String(data: errorData, encoding: .utf8)?
                            .trimmingCharacters(in: .whitespacesAndNewlines),
                        !errorString.isEmpty
                    {
                        Task { @MainActor in
                            Log.warning(
                                "Artwork script stderr: \(errorString)", category: .services)
                        }
                    }

                    let base64String =
                        String(data: data, encoding: .utf8)?
                        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                    if base64String.isEmpty {
                        continuation.resume(returning: nil)
                    } else {
                        continuation.resume(returning: Data(base64Encoded: base64String))
                    }
                } catch {
                    Task { @MainActor in
                        Log.error("Failed to run artwork fetcher: \(error)", category: .services)
                    }
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
