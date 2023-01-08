//
//  VPM.swift
//  VCCMac
//
//  Created by yuki on 2022/12/22.
//

import Foundation
import CoreUtil

enum VPMError: Error {
    case postCheckFailed(String)
    case checkFailed(String)
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
        catalyst.run(["new", name, templete.name, "--path", url.path])
            .tryMap{_ in
                var isDirectory: ObjCBool = false
                let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
                
                if !(exists && isDirectory.boolValue) {
                    throw VPMError.postCheckFailed("Project created but not exists at '\(url.path)'.")
                }
            }
    }

    func getProjectType(at url: URL) -> Promise<ProjectType, Error> {
        catalyst.run(["check", "project", url.path])
            .tryMap{ result in
                if result.starts(with: /\[\d\d:\d\d:\d\d ERR\]/) || !result.contains(/Project is/) {
                    return .notUnityProject
                }
                guard let projectType = result.firstMatch(of: /Project is (.*)/)?.1 else {
                    throw VPMError.checkFailed("Cannot get project type.")
                }
                
                let udonsharpURL = url.appending(component: "Packages/com.vrchat.udonsharp")
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
    
    func migrateProject(at url: URL, progress: PassthroughSubject<String, Never>) -> Promise<Void, Error> {
        return catalyst.run(["migrate", "project", url.path], interactiveStyle: .line(progress)).eraseToVoid()
    }
    
    // MARK: - Package -
    
    func updatePackage() -> Promise<Void, Error> {
        catalyst.run(["list", "repos"]).eraseToVoid()
    }
    
    func addPackage(_ packageVersion: PackageVersion, to projectURL: URL)  -> Promise<Void, Error> {
        catalyst.run(["add", "package", packageVersion.name, "--project", projectURL.path]).eraseToVoid()
    }
    
    // MARK: - Templates -
    
    func installTemplates() -> Promise<Void, Error> {
        catalyst.run(["install", "templates"]).eraseToVoid()
    }
    
    func listTemplates()-> Promise<[VPMTemplate], Error> {
        catalyst.run(["list", "templates"])
            .map{ result in
                let list = result.split(separator: "\n")
                    .compactMap{ $0.firstMatch(of: /\[\d\d:\d\d:\d\d INF\] (.*): (\/.+)/) }
                
                var templates = [VPMTemplate]()
                for template in list {
                    templates.append(VPMTemplate(
                        name: String(template.1),
                        url: URL(filePath: String(template.2))
                    ))
                }
                
                return templates.sorted(by: { $0.priority < $1.priority })
            }
    }
    
    // MARK: - Requirements -
    
    func checkHub() -> Promise<Void, Error> {
        catalyst.run(["check", "hub"]).eraseToVoid()
    }
    
    func checkUnity() -> Promise<Void, Error> {
        catalyst.run(["check", "unity"])
            .tryMap{ result in
                if result.contains("Unity is not installed") {
                    throw VPMError.checkFailed("Unity is not installed.")
                }
            }
    }
}
