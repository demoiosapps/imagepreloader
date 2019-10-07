//
//  ImagePreloaderCache.swift
//  ImagePreloader
//
//  Created by R on 16.09.2019.
//  Copyright © 2019 R. All rights reserved.
//

import UIKit

class ImagePreloaderCache {

    private static var _files: [(URL,UInt64)]?
    private static var files: [(URL,UInt64)] {
        get {
            if _files == nil {
                getFilesAndSize()
            }
            return _files!
        }
        set {
            _files = newValue
        }
    }
    private static var _size: UInt64?
    private static var size: UInt64 {
        get {
            if _size == nil {
                getFilesAndSize()
            }
            return _size!
        }
        set {
            _size = newValue
        }
    }
    
    private static let writeQueue = DispatchQueue(label: "ImagePreloaderCache.write", attributes: .concurrent)
    private static let readQueue = DispatchQueue(label: "ImagePreloaderCache.read", attributes: .concurrent)

    // Get current cache files and size
    private static func getFilesAndSize() {
        _files = []
        _size = 0
        let fileManager = FileManager.default
        if let cacheUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(ImagePreloader.cacheDir),
            let urls = try? fileManager.contentsOfDirectory(at: cacheUrl, includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey], options: .skipsHiddenFiles) {
            let filesWithAttrs = urls.map { url in
                (url, (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast, UInt64((try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0))
            }.sorted(by: { $0.1 < $1.1 })
            for (url, date, fileSize) in filesWithAttrs {
                _files!.append((url, fileSize))
                _size! += fileSize
                #if DEBUG
                if ImagePreloader.isDebug {
                    print("ImagePreloader - cache \(url) \(date) \(fileSize)")
                }
                #endif
            }
        }
        #if DEBUG
        if ImagePreloader.isDebug {
            print("ImagePreloader - cache (files: \(_files!.count), size: \(_size!))")
        }
        #endif
    }
    
    private static func fileSize(_ url: URL) -> UInt64 {
        do {
            return try FileManager.default.attributesOfItem(atPath: url.path)[FileAttributeKey.size] as! UInt64
        } catch {}
        return 0
    }
    
    static func clear() {
        writeQueue.async(flags: .barrier) {
            for (url, _) in files {
                try? FileManager.default.removeItem(at: url)
            }
            files = []
            size = 0
            #if DEBUG
            if ImagePreloader.isDebug {
                print("ImagePreloader - cache cleared")
            }
            #endif
        }
    }
    
    static func clean() {
        writeQueue.async(flags: .barrier) {
            while files.count > ImagePreloader.cacheMaxImages {
                removeOld()
            }
            while size > ImagePreloader.cacheMaxSize {
                removeOld()
            }
        }
    }
    
    private static func removeOld() {
        guard files.count > 0 else { return }
        let (url, fileSize) = files.first!
        let fileManager = FileManager.default
        do {
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
            }
            size -= fileSize
            files.remove(at: 0)
        } catch {
            #if DEBUG
            if ImagePreloader.isDebug {
                print("ImagePreloader - cache \(error.localizedDescription)")
            }
            #endif
        }
    }
    
    static func write(image: UIImage, for identifier: String) {
        writeQueue.async(flags: .barrier) {
            if ImagePreloader.cacheMaxImages > 0 {
                let fileManager = FileManager.default
                if let cacheUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(ImagePreloader.cacheDir) {
                    
                    // create cache dir
                    if !fileManager.fileExists(atPath: cacheUrl.path) {
                        do {
                            try fileManager.createDirectory(atPath: cacheUrl.path, withIntermediateDirectories: true, attributes: nil)
                        } catch {
                            #if DEBUG
                            if ImagePreloader.isDebug {
                                print("ImagePreloader - cache \(error.localizedDescription)")
                            }
                            #endif
                        }
                    }
                    
                    let fileUrl = cacheUrl.appendingPathComponent(identifier)
                    
                    // check file existence
                    if let index = files.firstIndex(where: { $0.0 == fileUrl }) {
                        let (url, fileSize) = files[index]
                        do {
                            if fileManager.fileExists(atPath: url.path) {
                                try fileManager.removeItem(at: url)
                            }
                            size -= fileSize
                            files.remove(at: index)
                        } catch {
                            #if DEBUG
                            if ImagePreloader.isDebug {
                                print("ImagePreloader - cache \(error.localizedDescription)")
                            }
                            #endif
                        }
                    }

                    // write file
                    do {
                        if let data = image.pngData() {
                            try data.write(to: fileUrl)
                        }
                        let imageFileSize = fileSize(fileUrl)
                        size += imageFileSize
                        files.append((fileUrl, imageFileSize))
                    } catch {
                        #if DEBUG
                        if ImagePreloader.isDebug {
                            print("ImagePreloader - cache \(error.localizedDescription)")
                        }
                        #endif
                    }

                    clean()
                }
            }
        }
    }
    
    static func image(for identifier: String, result: @escaping (_ image: UIImage?) -> Void) {
        readQueue.async {
            let fileManager = FileManager.default
            let path = "/\(ImagePreloader.cacheDir)/\(identifier)"
            if let url = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(path),
                fileManager.fileExists(atPath: url.path),
                let image = UIImage(contentsOfFile: url.path) {
                DispatchQueue.main.async {
                    result(image)
                }
            } else {
                DispatchQueue.main.async {
                    result(nil)
                }
            }
        }
    }
}
