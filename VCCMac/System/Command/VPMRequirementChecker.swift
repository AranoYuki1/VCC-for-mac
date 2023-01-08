//
//  VPMRequirements.swift
//  VCCMac
//
//  Created by yuki on 2022/12/27.
//

import Foundation
import CoreUtil

final class VPMRequirementChecker {
    let appModel: AppModel
    let command: VPMCommand
    
    init(appModel: AppModel, command: VPMCommand) {
        self.appModel = appModel
        self.command = command
    }
    
    struct FailureReason {
        let recoverable: Bool
        let failureType: FailureType
        
        enum FailureType {
            case vpmNotFound(URL)
            case vpmNotValid(message: String)
            case dotnetVersionIsNotValid(requiedVersion: String, message: String)
            case dotnetNotFound
            case unityHubNotFound
            case unityNotFound
            case unknown(message: String)
            
            var priority: Int {
                switch self {
                case .vpmNotFound: return 1
                case .vpmNotValid: return 1
                case .dotnetVersionIsNotValid: return 2
                case .dotnetNotFound: return 2
                case .unityHubNotFound: return 0
                case .unityNotFound: return 0
                case .unknown: return 3
                }
            }
        }
    }
    
    func failureReasons() -> Promise<[FailureReason], Never> {
        failureTypes()
            .map{ types in
                var reasons = [FailureReason]()
                
                var currentPriority = -1
                for type in types.sorted(by: { -$0.priority }) {
                    let isRecoverable = currentPriority <= type.priority
                    if isRecoverable {
                        currentPriority = type.priority
                    }
                    reasons.append(.init(recoverable: isRecoverable, failureType: type))
                }
                
                return reasons
            }
    }
    
    private func failureTypes() -> Promise<[FailureReason.FailureType], Never> {
        var failureReasons = [FailureReason.FailureType]()
                
        if !FileManager.default.isExecutableFile(atPath: appModel.commandSetting.pathToUnityExe) {
            failureReasons.append(.unityNotFound)
        }
        
        if !FileManager.default.isExecutableFile(atPath: appModel.commandSetting.pathToUnityHub) {
            failureReasons.append(.unityHubNotFound)
        }
        
        let dotnetCommand = DotnetCatalyst(logger: appModel.logger)
        
        let dotnetCheck = dotnetCommand.run(["tool", "--help"]).packToResult()
            .peek{
                do { _ = try $0.get() } catch {
                    failureReasons.append(.dotnetNotFound)
                }
            }
            .eraseToVoid()
        
        let vpmCheck = command.catalyst.run([]).packToResult()
            .peek{
                do {
                    _ = try $0.get()
                } catch let error as CatalystError {
                    switch error {
                    case let .binaryNotFound(url):
                        failureReasons.append(.vpmNotFound(url))
                    case .binaryNotExecutable:
                        failureReasons.append(.vpmNotValid(message: "VPM Binary is not executable."))
                    case let .commandExitWithNonZeroCode(_, message):
                        let dotnetVersionError = message.contains("You must install or update .NET to run this application")
                        let dotnetNotFoundError = message.contains("You must install .NET to run this application.")
                        
                        if dotnetVersionError {
                            let requiredVersion = message.firstMatch(of: /Framework: (.*)/)?.0 ?? "Unkown"
                            failureReasons.append(.dotnetVersionIsNotValid(requiedVersion: String(requiredVersion), message: message))
                        } else if dotnetNotFoundError {
                            failureReasons.append(.dotnetNotFound)
                        } else {
                            failureReasons.append(.vpmNotValid(message: message))
                        }
                    default:
                        failureReasons.append(.unknown(message: error.localizedDescription))
                    }
                } catch {
                    failureReasons.append(.unknown(message: error.localizedDescription))
                }
            }
            .eraseToVoid()
        
        return Promise.combineAll([dotnetCheck, vpmCheck])
            .map{_ in failureReasons }
    }
}


private struct DotnetCatalyst: CommandCatalyst {
    var logger: Logger
    
    var executableURL: URL { URL(filePath: "/usr/local/share/dotnet/dotnet") }
    
    init(logger: Logger) {
        self.logger = logger
    }
}
