//
//  ClearCacheFolder.swift
//  LectureToNotes
//
//  Created by Jacob Rodriguez on 4/10/25.
//
// Call 'ClearCahceFolder.shared.clearCacheFolder'
// CacheManager.swift
import Foundation

class CacheManager {
    static let shared = CacheManager()
    private init() {}
    
    func clearCacheFolder(completion: @escaping (Bool, Error?) -> Void) {
        let downloadsDir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let cacheFolder = downloadsDir.appendingPathComponent("LectureToNotesCache")
        
        DispatchQueue.global(qos: .utility).async {
            do {
                if FileManager.default.fileExists(atPath: cacheFolder.path) {
                    let contents = try FileManager.default.contentsOfDirectory(at: cacheFolder,
                                                                              includingPropertiesForKeys: nil)
                    for fileURL in contents {
                        try FileManager.default.removeItem(at: fileURL)
                    }
                    DispatchQueue.main.async {
                        completion(true, nil)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(false, nil)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false, error)
                }
            }
        }
    }
}
