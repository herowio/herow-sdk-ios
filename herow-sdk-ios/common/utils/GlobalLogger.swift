//
//  CPLogger.swift
//  ConnectPlaceCommon
//
//  Created by Connecthings on 04/07/2017.
//  Copyright © 2017 Connecthings. All rights reserved.
//

import Foundation


@objc public protocol LoggerDelegate {

    @objc func startDebug()

    @objc func stopDebug()

    @objc  func startLogInFile()

    @objc  func stopLogInFile()

    @objc  func verbose(_ message: Any )

    @objc  func debug(_ message: Any )

    @objc  func info(_ message: Any )

    @objc  func warning(_ message: Any )

    @objc   func error(_ message: Any )

    @objc func registerHerowId(herowId: String)
}

public enum MessageType: String {
    case verbose = "🟢 verbose"
    case debug = "🔵 debug"
    case info = "🟡 info"
    case warning = "🟠 warning"
    case error = "🔴 error"
}
@objc public class GlobalLogger: NSObject {

    var debug = false
    var debugInFile = false
    private var backgroundTaskId: UIBackgroundTaskIdentifier =  UIBackgroundTaskIdentifier.invalid
    @objc public static let shared = GlobalLogger()


    var logger: LoggerDelegate?

    @objc public func registerHerowId(herowId: String) {
        self.logger?.registerHerowId(herowId: herowId)
    }

    @objc public func registerLogger( logger: LoggerDelegate) {
        self.logger = logger
    }

    private func log(_ message: Any) {
        if debug {
            // print(String(describing:message))
        }
    }

    @objc public func startDebug() {
        debug = true
        if let logger = self.logger {
            logger.startDebug()
        }

    }

    @objc public func stopDebug() {
        debug = false
        if let logger = self.logger {
            logger.stopDebug()
        }
    }

    @objc public func startLogInFile() {
        debugInFile = true
        if let logger = self.logger {
            logger.startLogInFile()
        }
    }


    @objc public func stopLogInFile() {
        debugInFile = false
        if let logger = self.logger {
            logger.stopLogInFile()
        }
    }

    func format(fileName: String, functionName: String, lineNumber: Int, _ message: Any) -> String {
        var log = "\((fileName as NSString).lastPathComponent) - \(functionName) at line \(lineNumber): "
        log += String(describing:message)
        log += " - battery level: \(BatteryUtils.getCurrentLevel())%"
        return log
    }


    private func dispatchMessage(_ message: String , type: MessageType) {
        
        DispatchQueue.global(qos: .background).async {
            self.backgroundTaskId = UIApplication.shared.beginBackgroundTask(
                withName: "herow.io.GlobalLogger.backgroundTaskID",
                expirationHandler: {
                    UIApplication.shared.endBackgroundTask(self.backgroundTaskId)
                })

            let display = "[\(type.rawValue.uppercased())]" + " \(message)"
            if let logger = self.logger {
                switch type {
                case .debug:
                    logger.debug(display)
                case .verbose:
                    logger.verbose(display)
                case .info:
                    logger.info(display)
                case .warning:
                    logger.warning(display)
                case .error:
                    logger.error(display)
                }
            } else {
                self.log(display)
            }
            UIApplication.shared.endBackgroundTask(self.backgroundTaskId)
        }
    }
    public func verbose(_ message: Any,
                    fileName: String = #file,
                functionName: String = #function,
                  lineNumber: Int = #line) {

        let message = format(fileName: fileName, functionName: functionName, lineNumber: lineNumber, message)
        dispatchMessage(message,type: .verbose)

    }

    public func debug(_ message: Any,
                     fileName: String = #file,
                 functionName: String = #function,
                   lineNumber: Int = #line) {
        let message = format(fileName: fileName, functionName: functionName, lineNumber: lineNumber, message)
        dispatchMessage(message,type: .debug)   }

    public func info(_ message: Any,
                    fileName: String = #file,
                functionName: String = #function,
                  lineNumber: Int = #line) {
        let message = format(fileName: fileName, functionName: functionName, lineNumber: lineNumber, message)
        dispatchMessage(message,type: .info)    }

    public func warning(_ message: Any,
                       fileName: String = #file,
                   functionName: String = #function,
                     lineNumber: Int = #line) {
        let message = format(fileName: fileName, functionName: functionName, lineNumber: lineNumber, message)
        dispatchMessage(message,type: .warning)    }

    public func error(_ message: Any,
                     fileName: String = #file,
                 functionName: String = #function,
                   lineNumber: Int = #line) {
        let message = format(fileName: fileName, functionName: functionName, lineNumber: lineNumber, message)
        dispatchMessage(message,type: .error)   }
}
