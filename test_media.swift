import Foundation
import AppKit

// MARK: - Function Types
typealias MRMediaRemoteGetNowPlayingInfoFunction = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
typealias MRMediaRemoteGetNowPlayingApplicationPIDFunction = @convention(c) (DispatchQueue, @escaping (Int32) -> Void) -> Void

// MARK: - Load Framework
guard let handle = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_NOW) else { exit(1) }

guard let infoSym = dlsym(handle, "MRMediaRemoteGetNowPlayingInfo") else { exit(1) }
let getInfo = unsafeBitCast(infoSym, to: MRMediaRemoteGetNowPlayingInfoFunction.self)

// MARK: - Get Bundle ID via PID
var bundleID = "unknown"
if let pidSym = dlsym(handle, "MRMediaRemoteGetNowPlayingApplicationPID") {
    let getPID = unsafeBitCast(pidSym, to: MRMediaRemoteGetNowPlayingApplicationPIDFunction.self)
    let pidSemaphore = DispatchSemaphore(value: 0)
    getPID(DispatchQueue.main) { pid in
        if pid != 0, let app = NSRunningApplication(processIdentifier: pid) {
            bundleID = app.bundleIdentifier ?? "unknown"
        }
        pidSemaphore.signal()
    }
    RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
    _ = pidSemaphore.wait(timeout: .now() + 0.2)
}

// MARK: - Get Now Playing Info
var result = ""
let semaphore = DispatchSemaphore(value: 0)

getInfo(DispatchQueue.main) { info in
    guard let title = info["kMRMediaRemoteNowPlayingInfoTitle"] as? String, !title.isEmpty else {
        semaphore.signal()
        return
    }
    
    let artist = info["kMRMediaRemoteNowPlayingInfoArtist"] as? String ?? "Unknown Artist"
    let album = info["kMRMediaRemoteNowPlayingInfoAlbum"] as? String ?? "Unknown Album"
    
    var isPlaying = false
    if let rate = info["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? Double {
        isPlaying = rate > 0
    } else if let rate = info["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? NSNumber {
        isPlaying = rate.doubleValue > 0
    }
    
    var artworkBase64 = ""
    if let artworkData = info["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data {
        artworkBase64 = artworkData.base64EncodedString()
    }
    
    result = "\(title)\t\(artist)\t\(album)\t\(isPlaying)\t\(bundleID)\t\(artworkBase64)"
    semaphore.signal()
}

RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.3))
_ = semaphore.wait(timeout: .now() + 0.5)

if result.isEmpty {
    print("No music playing or unable to fetch info.")
} else {
    print(result)
}