//
//  VPM.swift
//  VCCMac
//
//  Created by yuki on 2022/12/22.
//

import Foundation
import CoreUtil

enum VPMError: Error, CustomStringConvertible {
    case postCheckFailed(String)
    case checkFailed(String)
    
    var description: String {
        switch self {
        case .checkFailed(let message): return message.trimmingCharacters(in: .whitespacesAndNewlines)
        case .postCheckFailed(let message): return message.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}

struct VPMTemplate {
    let name: String
    let url: URL
}


final class VPMCommand {
    let catalyst: VPMCatalyst
    
    init(catalyst: VPMCatalyst) {
        self.catalyst = catalyst
    }
    
    // MARK: - Project -
    
    func newProject(name: String, templete: VPMTemplate, at url: URL) -> Promise<Void, Error> {
        catalyst.run(["new", name, templete.name, "--path", url.path]).complete
            .tryMap{_ in
                var isDirectory: ObjCBool = false
                let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
                
                if !(exists && isDirectory.boolValue) {
                    throw VPMError.postCheckFailed("Project created but not exists at '\(url.path)'.")
                }
            }
    }

    func getProjectType(at url: URL) -> Promise<ProjectType, Error> {
        catalyst.run(["check", "project", url.path]).complete
            .tryMap{ _result in
                let result = _result as NSString
                                
                if !result.matches(#"^\[\d\d:\d\d:\d\d ERR\]"#).isEmpty || result.matches("Project is").isEmpty {
                    return .notUnityProject
                }
                
                guard let projectTypeMatch = result.matches("Project is (.*)").first else {
                    throw VPMError.checkFailed("Cannot get project type.")
                }
                
                let projectType = result.substring(with: projectTypeMatch.range(at: 1))
                
                let udonsharpURL = url.appendingPathComponent("Packages/com.vrchat.udonsharp")
                let udonsharpExists = FileManager.default.fileExists(at: udonsharpURL)
                        
                switch projectType {
                case "LegacySDK3Avatar": return .legacyAvatar
                case "LegacySDK3World": return .legacyWorld
                case "LegacySDK3UdonSharp": return .legacyUdonSharp
                case "LegacySDK3Base": return .legacyBase
                case "AvatarVPM": return .avatarVPM
                    
                case "WorldVPM":
                    if udonsharpExists { return .udonSharpVPM }
                    return .worldVPM
                    
                case "StarterVPM": return .baseVPM
                    
                default: return .unkown(String(projectType))
                }
            }
    }
    
    func migrateProject(at url: URL, progress: PassthroughSubject<String, Never>, inplace: Bool) -> Promise<Void, Error> {
        var arguments = ["migrate", "project", url.path]
        if inplace { arguments.append("--inplace") }
        return catalyst.run(arguments, interactiveStyle: .line(progress)).complete.eraseToVoid()
    }
    
    // MARK: - Package -
    
    func addPackage(_ packageVersion: PackageJSON, to projectURL: URL)  -> Promise<Void, Error> {
        catalyst.run(["add", "package", packageVersion.name, "--project", projectURL.path]).complete.eraseToVoid()
    }
    
    // MARK: - Repo -
    
    func listRepo(_ url: URL) -> Promise<Void, Error> {
        catalyst.run(["list", "repo", url.absoluteString]).complete.eraseToVoid()
    }
    
    func listRepos() -> Promise<Void, Error> {
        catalyst.run(["list", "repos"]).complete.eraseToVoid()
    }
    
    func removeRepo(_ id: String) -> Promise<Void, Error> {
        catalyst.run(["remove", "repo", id]).complete.eraseToVoid()
    }
    
    func addRepo(_ url: URL) -> Promise<Void, Error> {
        catalyst.run(["add", "repo", url.absoluteString]).complete
            .tryMap{ result in
                if !result.matches(#"^\[\d\d:\d\d:\d\d ERR\]"#).isEmpty {
                    let message = String(result[result.index(result.startIndex, offsetBy: 15)...])
                    throw VPMError.checkFailed(message)
                }
                if !result.matches(#"^\[\d\d:\d\d:\d\d WRN\]"#).isEmpty {
                    let message = String(result[result.index(result.startIndex, offsetBy: 15)...])
                    throw VPMError.checkFailed(message)
                }
                
            }
            .eraseToVoid()
    }
    
    // MARK: - Templates -
    
    func installTemplates() -> Promise<Void, Error> {
        catalyst.run(["install", "templates"]).complete.eraseToVoid()
    }
    
    func listTemplates() -> Promise<[VPMTemplate], Error> {
        catalyst.run(["list", "templates"]).complete
            .map{ result in
                let list = result.split(separator: "\n")
                    .map{ String($0) as NSString }
                    .compactMap{ str -> (name: String, url: String)? in
                        let matches = str.matches(#"\[\d\d:\d\d:\d\d INF\] (.*): (\/.+)"#)
                        guard let match = matches.first else { return nil }
                        let name = str.substring(with: match.range(at: 1))
                        let url = str.substring(with: match.range(at: 2))
                        
                        return (name: name, url: url)
                    }
                
                var templates = [VPMTemplate]()
                for template in list {
                    templates.append(VPMTemplate(
                        name: String(template.name),
                        url: URL(fileURLWithPath: String(template.url))
                    ))
                }
                
                return templates.sorted(by: { $0.priority < $1.priority })
            }
    }
    
    // MARK: - Requirements -
    
    func checkHub() -> Promise<Void, Error> {
        catalyst.run(["check", "hub"]).complete.eraseToVoid()
    }
    
    func checkUnity() -> Promise<Void, Error> {
        catalyst.run(["check", "unity"]).complete
            .tryMap{ result in
                if result.contains("Unity is not installed") {
                    throw VPMError.checkFailed("Unity is not installed.")
                }
            }
    }
}

extension NSString {
    func matches(_ regex: String) -> [NSTextCheckingResult] {
        try! NSRegularExpression(pattern: regex).matches(in: self as String, range: .init(location: 0, length: self.length))
    }
}
