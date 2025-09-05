import Foundation

final class DownloadManager {
    static let shared = DownloadManager()
    private init() {}
    
    func downloadTrack(from remoteURL: URL,
                       suggestedName: String? = nil) async throws -> URL {
        let (tmpURL, resp) = try await URLSession.shared.download(from: remoteURL)
        
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let serverName = resp.suggestedFilename ?? remoteURL.lastPathComponent
        let serverBase = URL(fileURLWithPath: serverName).deletingPathExtension().lastPathComponent
        let base = (suggestedName?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 } ?? serverBase
        
        var ext = URL(fileURLWithPath: serverName).pathExtension
        if ext.isEmpty { ext = "mp3" }
        
        let fm = FileManager.default
        let lib = try fm.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let folder = lib.appendingPathComponent("Audio", isDirectory: true)
        if !fm.fileExists(atPath: folder.path) {
            try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        
        let safeBase = Self.safeFilename(base)
        var dst = folder.appendingPathComponent("\(safeBase).\(ext)")
        var i = 1
        while fm.fileExists(atPath: dst.path) {
            dst = folder.appendingPathComponent("\(safeBase)-\(i).\(ext)")
            i += 1
        }
        
        try fm.moveItem(at: tmpURL, to: dst)
        return dst
    }
    
    private static func safeFilename(_ s: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        let cleaned = s.components(separatedBy: invalid).joined(separator: "_")
        return cleaned.isEmpty ? "file" : cleaned
    }
}
