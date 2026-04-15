//
//  FileImportService.swift
//  MusicPlayer
//
//  本地音乐文件导入服务
//

import Foundation
import UIKit
import AVFoundation

/// 文件导入服务
class FileImportService: NSObject, ObservableObject {
    static let shared = FileImportService()

    @Published var isImporting = false
    @Published var importProgress: Double = 0
    @Published var importedSongs: [Song] = []

    // MARK: - Import from Document Picker
    func importFiles(completion: @escaping ([Song]) -> Void) {
        let documentPicker = UIDocumentPickerViewController(
            forOpeningContentTypes: [
                UTType.mp3,
                UTType.m4a,
                UTType.audio,
                UTType(filenameExtension: "flac")!,
                UTType(filenameExtension: "wav")!,
                UTType(filenameExtension: "aac")!
            ],
            asCopy: true
        )

        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = true
        documentPicker.shouldShowFileExtensions = true

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(documentPicker, animated: true)
        }

        self.importCompletion = completion
    }

    private var importCompletion: (([Song]) -> Void)?

    // MARK: - Import from URL
    func importFile(from url: URL) async -> Song? {
        do {
            // 确保文件可访问
            guard url.startAccessingSecurityScopedResource() else {
                return nil
            }

            // 获取文件属性
            let asset = AVAsset(url: url)
            let duration = try await asset.load(.duration).seconds

            // 提取元数据
            let metadata = try await extractMetadata(from: asset)

            // 创建持久化URL（将文件复制到Documents目录）
            let permanentURL = copyToDocuments(originalURL: url)

            // 停止安全范围访问
            url.stopAccessingSecurityScopedResource()

            let song = Song(
                title: metadata.title ?? url.deletingPathExtension().lastPathComponent,
                artist: metadata.artist,
                album: metadata.album,
                duration: duration,
                fileURL: permanentURL,
                artwork: metadata.artwork,
                dateAdded: Date()
            )

            return song
        } catch {
            print("Failed to import file: \(error)")
            return nil
        }
    }

    // MARK: - Extract Metadata
    private func extractMetadata(from asset: AVAsset) async throws -> AudioMetadata {
        let metadataItems = try await asset.load(.commonMetadata)

        var title: String?
        var artist: String?
        var album: String?
        var artwork: Data?

        for item in metadataItems {
            if let value = try await item.load(.value) {
                if item.commonKey == .commonKeyTitle {
                    title = value as? String
                } else if item.commonKey == .commonKeyArtist {
                    artist = value as? String
                } else if item.commonKey == .commonKeyAlbumName {
                    album = value as? String
                } else if item.commonKey == .commonKeyArtwork {
                    artwork = value as? Data
                }
            }
        }

        return AudioMetadata(title: title, artist: artist, album: album, artwork: artwork)
    }

    // MARK: - Copy to Documents
    private func copyToDocuments(originalURL: URL) -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let musicDirectory = documentsDirectory.appendingPathComponent("Music", isDirectory: true)

        // 创建音乐目录
        if !FileManager.default.fileExists(atPath: musicDirectory.path) {
            try? FileManager.default.createDirectory(at: musicDirectory, withIntermediateDirectories: true)
        }

        let destinationURL = musicDirectory.appendingPathComponent(originalURL.lastPathComponent)

        // 如果目标文件已存在，先删除
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try? FileManager.default.removeItem(at: destinationURL)
        }

        // 复制文件
        try? FileManager.default.copyItem(at: originalURL, to: destinationURL)

        return destinationURL
    }

    // MARK: - Scan Directory
    func scanDirectory(at url: URL) async -> [Song] {
        var songs: [Song] = []

        guard url.startAccessingSecurityScopedResource() else {
            return songs
        }

        let fileManager = FileManager.default
        let supportedExtensions = ["mp3", "m4a", "flac", "wav", "aac", "ogg"]

        do {
            let contents = fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])

            isImporting = true
            let totalFiles = contents.count

            for (index, fileURL) in contents.enumerated() {
                if supportedExtensions.contains(fileURL.pathExtension.lowercased()) {
                    if let song = await importFile(from: fileURL) {
                        songs.append(song)
                    }
                }

                importProgress = Double(index + 1) / Double(totalFiles)
            }

            isImporting = false
            importProgress = 0
        } catch {
            print("Failed to scan directory: \(error)")
        }

        url.stopAccessingSecurityScopedResource()

        return songs
    }
}

// MARK: - Audio Metadata Structure
struct AudioMetadata {
    let title: String?
    let artist: String?
    let album: String?
    let artwork: Data?
}

// MARK: - Document Picker Delegate
extension FileImportService: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        Task {
            isImporting = true
            var imported: [Song] = []

            for (index, url) in urls.enumerated() {
                if let song = await importFile(from: url) {
                    imported.append(song)
                    importedSongs.append(song)
                }
                importProgress = Double(index + 1) / Double(urls.count)
            }

            isImporting = false
            importProgress = 0

            importCompletion?(imported)
            importCompletion = nil
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        isImporting = false
        importProgress = 0
        importCompletion?([])
        importCompletion = nil
    }
}