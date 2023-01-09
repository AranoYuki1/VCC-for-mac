//
//  Logger.swift
//  VCCMac
//
//  Created by yuki on 2022/12/29.
//

import CoreUtil

public protocol LoggerSubscriber: Actor {
    var minimumLevel: Logger.Level { get }
    
    func receive(_ log: Logger.Log)
}

final public class Logger {
    public enum Level: Int, CaseIterable, Comparable, Equatable {
        case debug = 0
        case info
        case log
        case warn
        case error
        
        public static func < (lhs: Logger.Level, rhs: Logger.Level) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
    public struct Log: CustomStringConvertible {
        public let date: Date
        public let level: Level
        public let message: String
        public let file: StaticString
        public let line: UInt
        
        static let formatter = DateFormatter() => {
            $0.dateFormat = "yyyy/MM/dd HH:mm"
        }
        
        public var description: String {
            "\(Log.formatter.string(from: date)) [\(self.level)] \(self.file):\(self.line) \(self.message)"
        }
    }
    
    private var subscribers = [LoggerSubscriber]()
    
    public init() {}
    
    public func subscribe<T: LoggerSubscriber>(_ subscriber: T) {
        self.subscribers.append(subscriber)
    }

    public func debug(_ message: String, file: StaticString = #fileID, line: UInt = #line) {
        self.sendLog(message, for: .debug, file: file, line: line)
    }
    public func debug(_ error: Error, file: StaticString = #fileID, line: UInt = #line) {
        self.sendLog("\(error)", for: .debug, file: file, line: line)
    }
    public func info(_ message: String, file: StaticString = #fileID, line: UInt = #line) {
        self.sendLog(message, for: .info, file: file, line: line)
    }
    public func log(_ message: String, file: StaticString = #fileID, line: UInt = #line) {
        self.sendLog(message, for: .log, file: file, line: line)
    }
    public func warn(_ message: String, file: StaticString = #fileID, line: UInt = #line) {
        self.sendLog(message, for: .warn, file: file, line: line)
    }
    public func error(_ message: String, file: StaticString = #fileID, line: UInt = #line) {
        self.sendLog(message, for: .error, file: file, line: line)
    }
    public func error(_ error: Error, file: StaticString = #fileID, line: UInt = #line) {
        self.sendLog("\(error)", for: .error, file: file, line: line)
    }
    
    private func sendLog(_ message: String, for level: Level, file: StaticString, line: UInt) {
        let log = Log(date: Date(), level: level, message: message, file: file, line: line)
        Task.detached{
            for subscriber in self.subscribers where await log.level >= subscriber.minimumLevel {
                await subscriber.receive(log)
            }
        }
    }
}

extension Logger {
    public func subscribe(minimumLevel: Level, fileHandle: FileHandle) {
        self.subscribe(FileHandleLoggerSubscriber(minimumLevel: minimumLevel, fileHandle: fileHandle))
    }
    public func subscribe(minimumLevel: Level, _ handler: @escaping @Sendable (Logger.Log) -> ()) {
        self.subscribe(ClosureLoggerSubscriber(minimumLevel: minimumLevel, handler: handler))
    }
}

private actor FileHandleLoggerSubscriber: LoggerSubscriber {
    let minimumLevel: Logger.Level
    
    private let fileHandle: FileHandle

    init(minimumLevel: Logger.Level, fileHandle: FileHandle) {
        self.minimumLevel = minimumLevel
        self.fileHandle = fileHandle
    }
    
    func receive(_ log: Logger.Log) {
        try? fileHandle.write(contentsOf: log.description.data(using: .utf8)!)
        try? fileHandle.write(contentsOf: "\n".data(using: .utf8)!)
    }
    
    deinit {
        try? fileHandle.close()
    }
}

private actor ClosureLoggerSubscriber: LoggerSubscriber {
    let minimumLevel: Logger.Level
    let handler: @Sendable (Logger.Log) -> ()
    
    init(minimumLevel: Logger.Level, handler: @escaping @Sendable (Logger.Log) -> ()) {
        self.minimumLevel = minimumLevel
        self.handler = handler
    }
    
    func receive(_ log: Logger.Log) {
        handler(log)
    }
}

