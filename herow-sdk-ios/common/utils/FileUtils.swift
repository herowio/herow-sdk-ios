//
//  FileUtils.swift
//  ConnectPlaceCommon
//
//  Created by Ludovic Vimont on 05/10/2017.
//  Copyright © 2017 Connecthings. All rights reserved.
//

import Foundation
import PromiseKit

public class FileUtils {
    private static let filename = "connectplace-settings"

    public static func generateDocumentPath(directory: FileManager.SearchPathDirectory, fileName: String)
        throws -> URL {
            let urls = FileManager.default.urls(for: directory, in: .userDomainMask)
            if let documentDirectory: URL = urls.first {
                return documentDirectory.appendingPathComponent(fileName)
            } else {
                throw NSError(domain: "com.connecthings.file",
                              code: 0,
                              userInfo: [NSLocalizedDescriptionKey: "Folder does not exist"])
            }
    }

    public static func fileExists(directory: FileManager.SearchPathDirectory, filename: String) -> Bool {
        let path = NSSearchPathForDirectoriesInDomains(directory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        if let pathComponent = url.appendingPathComponent(filename) {
            let filePath = pathComponent.path
            let fileManager = FileManager.default
            return fileManager.fileExists(atPath: filePath)
        }
        return false
    }

    public static func getFileAttributes(directory: FileManager.SearchPathDirectory, filename: String)
        -> [FileAttributeKey: Any]? {
        do {
            let path = NSSearchPathForDirectoriesInDomains(directory, .userDomainMask, true)[0] as String
            let url = NSURL(fileURLWithPath: path)
            if let pathComponent = url.appendingPathComponent(filename) {
                let filePath = pathComponent.path
                return try? FileManager.default.attributesOfItem(atPath: filePath)
            }
        }
        return nil
    }

    public static func deleteFile(directory: FileManager.SearchPathDirectory, fileName: String) throws {
        let documentUrl = try generateDocumentPath(directory: directory, fileName: fileName)
        try FileManager.default.removeItem(at: documentUrl)
    }

    public static func loadFromFile(directory: FileManager.SearchPathDirectory, fileName: String) -> Promise<Data> {
        return Promise<Data> { seal in
            do {
                let finalDocument = try generateDocumentPath(directory: directory, fileName: fileName)
                if try finalDocument.checkResourceIsReachable() {
                    DispatchQueue.global(qos: .userInitiated).async {
                        do {
                            let data = try Data(contentsOf: finalDocument)
                            seal.fulfill(data)
                        } catch {
                            seal.reject(error)
                        }
                    }
                }
            } catch {
                seal.reject(error)
            }
        }
    }

    public static func saveToFile(directory: FileManager.SearchPathDirectory,
                                  fileName: String, data: Data) -> Promise<Data> {
        return Promise<Data> { seal in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let finalDocument: URL = try generateDocumentPath(directory: directory, fileName: fileName)
                    try data.write(to: finalDocument, options: Data.WritingOptions.atomic)
                    seal.fulfill((data))
                } catch {
                    seal.reject(error)
                }
            }
        }
    }

    public static func migrateFile(_ fileName: String, fromDirectory source: FileManager.SearchPathDirectory, toDirectory target: FileManager.SearchPathDirectory) {
        let fileManager = FileManager.default
        let sourceUrl =  fileManager.urls(for: source, in: .userDomainMask).first!
        let sourcePath = sourceUrl.appendingPathComponent(fileName).absoluteURL.path
        let targetUrl = fileManager.urls(for: target, in: .userDomainMask).first!
        let targetPath = targetUrl.appendingPathComponent(fileName).absoluteURL.path
        if fileManager.fileExists(atPath: sourcePath) == true && fileManager.fileExists(atPath: targetPath) == false {
            do {
                try fileManager.moveItem(atPath: sourcePath, toPath: targetPath)
                GlobalLogger.shared.debug("move \(sourcePath) to  \(targetPath)")
            } catch let error as NSError {
                GlobalLogger.shared.error("Ooops! Something went wrong: \(error)")
            }
        }
    }

    public static func saveUnbackedFileToApplicationSupportFolder(fileName: String, data: Data) -> Promise<Data> {
        self.createAppSupportDirectoryIfNeeded()
        return self.saveToFile(directory: .applicationSupportDirectory, fileName: fileName, data: data).get { data -> Void in
            self.markFileAsExcludedFromBackup(directory: .applicationSupportDirectory, fileName: fileName)
        }
    }

    public static func markFileAsExcludedFromBackup(directory: FileManager.SearchPathDirectory, fileName: String) {
        do {
            var finalDocument: URL = try generateDocumentPath(directory: directory, fileName: fileName)
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try finalDocument.setResourceValues(resourceValues)
        } catch {
            GlobalLogger.shared.error(error.localizedDescription)
        }
    }

    public static func createAppSupportDirectoryIfNeeded() {
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        if let appSupportDirectory: URL = urls.first {
            if FileManager.default.fileExists(atPath: appSupportDirectory.absoluteString) == false {
                do {
                    try FileManager.default.createDirectory(at: appSupportDirectory, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }

    public static func loadPlist(_ bundle: Bundle) -> NSDictionary? {
        var mainDictionary: NSDictionary?
        var frameworkDictionary: NSDictionary?
        if let path = Bundle.main.path(forResource: filename, ofType: "plist") {
            mainDictionary = NSDictionary(contentsOfFile: path)
        }
        if let frameworkPath = bundle.path(forResource: filename, ofType: "plist") {
            frameworkDictionary = NSDictionary(contentsOfFile: frameworkPath)
        }
        if let mainContent = mainDictionary {
            if let frameworkContent = frameworkDictionary {
                return frameworkContent.merge(mainContent)
            }
        }
        if let frameworkContent = frameworkDictionary {
            return frameworkContent
        }
        return mainDictionary
    }

    public static func loadFromFileSync(fileName: String) -> Data? {
        do {
            let finalDocument = try generateDocumentPath(directory: .applicationSupportDirectory, fileName: fileName)
            if try finalDocument.checkResourceIsReachable() {
                do {
                    let data = try Data(contentsOf: finalDocument)
                    return data

                } catch {
                    return nil
                }
            }
        } catch {
            return nil
        }
        return nil
    }

    public static func saveToFileSync(fileName: String, data: Data) -> Bool {
        do {
            let finalDocument: URL = try generateDocumentPath(directory: .applicationSupportDirectory, fileName: fileName)
            try data.write(to: finalDocument, options: Data.WritingOptions.atomic)
            return true

        } catch {
            return false
        }
    }

    public static func deleteFileSync( fileName: String) -> Bool {
        do {
            let documentUrl = try generateDocumentPath(directory: .applicationSupportDirectory, fileName: fileName)
            try FileManager.default.removeItem(at: documentUrl)
            return true
        } catch {
            return false
        }
    }
}
