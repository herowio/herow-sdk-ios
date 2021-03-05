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

    @objc  func trace(_ message: Any )

    @objc  func debug(_ message: Any )

    @objc  func info(_ message: Any )

    @objc  func warning(_ message: Any )

    @objc   func error(_ message: Any )
}

public enum MessageType: String {
    case trace
    case debug
    case info
    case warning
    case error
}
@objc public class GlobalLogger: NSObject {
    var debug = false
    var debugInFile = false
    @objc public static let shared = GlobalLogger()


    weak var logger: LoggerDelegate?


    @objc public func registerLogger( logger: LoggerDelegate) {
        self.logger = logger
    }

    private func log(_ message: Any) {
        if debug {
            print(String(describing:message))
        }
    }

    @objc public func startDebug() {
        debug = true
        if let logger = self.logger {
            logger.stopDebug()
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
        log += " - \(BatteryUtils.getCurrentLevel())%"
        return log
    }


    private func dispatchMessage(_ message: String , type: MessageType) {

        if let logger = self.logger {
            logger.trace(message)
        } else {
            log(type.rawValue + " \(message)")
        }
    }
    public func trace(_ message: Any,
                    fileName: String = #file,
                functionName: String = #function,
                  lineNumber: Int = #line) {

        let message = format(fileName: fileName, functionName: functionName, lineNumber: lineNumber, message)
        dispatchMessage(message,type: .trace)

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
