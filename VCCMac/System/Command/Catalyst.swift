//
//  Catalyst.swift
//  VCCMac
//
//  Created by yuki on 2022/12/26.
//

import Foundation
import CoreUtil

enum CatalystInteractiveStyle {
    case none
    case byte(PassthroughSubject<UInt8, Never>)
    case character(PassthroughSubject<Character, Never>)
    case line(PassthroughSubject<String, Never>, skipEmptyLine: Bool = true)
}

protocol CommandCatalyst {
    var executableURL: URL { get }
    var logger: Logger { get }
}

struct CatalystTask {
    let complete: Promise<String, Error>
    private let process: Process
    
    init(complete: Promise<String, Error>, process: Process) {
        self.complete = complete
        self.process = process
    }
    
    func terminate() {
        self.process.terminate()
    }
}

extension CommandCatalyst {
    
    @discardableResult
    func run(_ argumenets: [String], interactiveStyle: CatalystInteractiveStyle = .none) -> CatalystTask {
        let task = Process()

        let complete = Promise<String, Error>.tryDispatch(on: .main) { resolve, reject in
            do {
                try self.checkExecutable()
            } catch {
                reject(error)
            }
            
            let command = "\(executableURL.lastPathComponent) \(argumenets.joined(separator: " "))"
            
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            
            task.executableURL = executableURL
            task.arguments = argumenets
            task.standardOutput = outputPipe
            task.standardError = errorPipe
            
            logger.debug(command)
                        
            let stream = outputPipe.fileHandleForReading.stream()
            var cancellables = [AnyCancellable]()
            var defaultOutput: String?
            
            switch interactiveStyle {
            case .none:
                stream.readToEnd().sink{ defaultOutput = String(data: $0, encoding: .utf8) }
            case .byte(let publisher):
                 stream.bytesPublisher().sink{ publisher.send($0) }.store(in: &cancellables)
            case .character(let publisher):
                stream.characterPublisher(using: .utf8)
                    .sink(receiveCompletion: {_ in }, receiveValue: { publisher.send($0) })
                    .store(in: &cancellables)
            case let .line(publisher, skipEmptyLine):
                stream.linePublisher(using: .utf8, skipEmptyLine: skipEmptyLine)
                    .sink(receiveCompletion: {_ in }, receiveValue: {
                        publisher.send($0)
                    })
                    .store(in: &cancellables)
            }
            
            do {
                try task.run()
                
                task.terminationHandler = {_ in
                    if task.terminationStatus != 0 {
                        let errorMessage = errorPipe.readStringToEndOfFile ?? ""
                        reject(CatalystError.commandExitWithNonZeroCode(code: task.terminationStatus, message: errorMessage))
                    }
                    
                    cancellables.forEach{ $0.cancel() }
                    
                    let output = defaultOutput ?? ""
                    logger.debug(output.trimmingCharacters(in: .whitespacesAndNewlines))
                    resolve(output)
                }
            } catch {
                reject(CatalystError.failToStartCommand(error))
            }
        }
        
        return CatalystTask(complete: complete, process: task)
    }
    
    func checkExecutable() throws {
        if !FileManager.default.fileExists(atPath: executableURL.path) {
            throw CatalystError.binaryNotFound(executableURL)
        }
        if !FileManager.default.isExecutableFile(atPath: executableURL.path) {
            throw CatalystError.binaryNotExecutable(executableURL)
        }
    }
}


enum CatalystError: LocalizedError {
    case binaryNotFound(URL)
    case binaryNotExecutable(URL)
    case failToStartCommand(Error)
    case commandExitWithNonZeroCode(code: Int32, message: String)
    
    var errorDescription: String? {
        switch self {
        case .binaryNotExecutable(let url):
            return "Binary at '\(url.path)' is not excutable."
        case .binaryNotFound(let url):
            return "Command binary not found at '\(url.path)'."
        case .failToStartCommand(let error):
            return "Fail to start vpm commad (\(error))"
        case .commandExitWithNonZeroCode(let code, let message):
            if message.isEmpty {
                return "Command exit with non zero code '\(code)'"
            } else {
                return "Command exit with non zero code '\(code)'\n\(message)"
            }
        }
    }
}
