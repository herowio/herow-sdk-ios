//
//  CPLogger.swift
//  ConnectPlaceCommon
//
//  Created by Connecthings on 04/07/2017.
//  Copyright © 2017 Connecthings. All rights reserved.
//

import Foundation
import CocoaLumberjack

@objc public class GlobalLogger: NSObject {
    @objc public static let shared = GlobalLogger()
    var loggerFile: DDFileLogger?

    private override init() {
        DDLog.add(DDASLLogger.sharedInstance, with: DDLogLevel.info)
        super.init()
    }

    @objc public func startDebug() {
        DDLog.remove(DDASLLogger.sharedInstance)
        DDLog.add(DDASLLogger.sharedInstance, with: DDLogLevel.verbose)
    }

    @objc public func stopDebug() {
        DDLog.remove(DDASLLogger.sharedInstance)
        DDLog.add(DDASLLogger.sharedInstance, with: DDLogLevel.info)
    }

    @objc public func startLogInFile() {
        if loggerFile == nil {
            loggerFile = DDFileLogger()
            loggerFile?.rollingFrequency = 60 * 60 * 24 // 24 hour rolling
            loggerFile?.logFileManager.maximumNumberOfLogFiles = 7
        }
        if let loggerFile = loggerFile {
            DDLog.add(loggerFile, with: DDLogLevel.verbose)
        }
    }

    @objc public func getLogData() -> [Data] {
        var logFileDataArray = [Data]()
        if let logFilePaths = loggerFile?.logFileManager.sortedLogFilePaths {
            for logFilePath in logFilePaths {
                let fileURL = URL(fileURLWithPath: logFilePath)
                if let logFileData =
                    try? Data(contentsOf: fileURL, options: Data.ReadingOptions.mappedIfSafe) {
                    logFileDataArray.insert(logFileData, at: 0)
                }
            }
        }
        return logFileDataArray
    }

    @objc public func stopLogInFile() {
        if let loggerFile = loggerFile {
            DDLog.remove(loggerFile)
        }
    }

    func format(fileName: String, functionName: String, lineNumber: Int, _ items: Any ...) -> String {
        var log = "\((fileName as NSString).lastPathComponent) - \(functionName) at line \(lineNumber): "
        log += items.map({ String(describing: $0) }).joined(separator: " ")
        log += " - \(BatteryUtils.getCurrentLevel())%"
        return log
    }

    public func trace(_ items: Any...,
                    fileName: String = #file,
                functionName: String = #function,
                  lineNumber: Int = #line) {
        DDLogVerbose(format(fileName: fileName, functionName: functionName, lineNumber: lineNumber, items))
    }

    public func debug(_ items: Any...,
                     fileName: String = #file,
                 functionName: String = #function,
                   lineNumber: Int = #line) {
        DDLogDebug(format(fileName: fileName, functionName: functionName, lineNumber: lineNumber, items))
    }

    public func info(_ items: Any...,
                    fileName: String = #file,
                functionName: String = #function,
                  lineNumber: Int = #line) {
        DDLogInfo(format(fileName: fileName, functionName: functionName, lineNumber: lineNumber, items))
    }

    public func warning(_ items: Any...,
                       fileName: String = #file,
                   functionName: String = #function,
                     lineNumber: Int = #line) {
        DDLogWarn(format(fileName: fileName, functionName: functionName, lineNumber: lineNumber, items))
    }

    public func error(_ items: Any...,
                     fileName: String = #file,
                 functionName: String = #function,
                   lineNumber: Int = #line) {
        DDLogError(format(fileName: fileName, functionName: functionName, lineNumber: lineNumber, items))
    }
}
