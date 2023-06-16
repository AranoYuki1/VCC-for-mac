//
//  VCCCommandSetting.swift
//  VCCMac
//
//  Created by yuki on 2023/01/04.
//

import CoreUtil
import DictionaryCoder

struct VCCCommandSettingError: Error, CustomStringConvertible {
    let description: String
}

final class VCCCommandSetting {
    @Observable var pathToUnityExe: String = "" {
        didSet { self.dictionary["pathToUnityExe"] = pathToUnityExe; save() }
    }
    @Observable var pathToUnityHub: String = "" {
        didSet { self.dictionary["pathToUnityHub"] = pathToUnityHub; save() }
    }
    
    struct UserRepo: Codable {
        let localPath: String
        let url: URL
        let name: String
        let id: String
    }
    
    @Observable private(set) var userRepos: [UserRepo] = []
    
    let settingURL = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".local/share/VRChatCreatorCompanion/settings.json")
    weak var appModel: AppModel?
    
    private var dictionary: NSMutableDictionary
    
    func reload() throws {
        self.dictionary = try JSONSerialization.jsonObject(with: Data(contentsOf: settingURL), options: [.mutableContainers]) as! NSMutableDictionary
        self.reapplyDictionary()
        self.appModel?.reloadPublisher.send()
    }
    
    private func save() {
        try? JSONSerialization.data(withJSONObject: dictionary, options: [
            .prettyPrinted, .withoutEscapingSlashes, .sortedKeys
        ]).write(to: settingURL)
        
        appModel?.reloadPublisher.send()
    }
    
    public func autoFixPathToUnityHub() throws {
        guard !FileManager.default.isExecutableFile(atPath: pathToUnityHub) else { return }
        self.pathToUnityHub = try findPathToUnityHub().path
    }
    
    private func findPathToUnityHub() throws -> URL {
        let url0 = URL(fileURLWithPath: "/Applications/Unity Hub.app/Contents/MacOS/Unity Hub")
        if FileManager.default.isExecutableFile(atPath: url0.path) {
            return url0
        }
        
        let url1 = URL(fileURLWithPath: "/Applications/Unity/Hub/Editor")
        if FileManager.default.isExecutableFile(atPath: url1.path) {
            return url1
        }
        
        throw VCCCommandSettingError(description: "Cannot Find Unity Hub.")
    }
    
    public func autoFixPathToUnityExe() throws {
        guard !FileManager.default.isExecutableFile(atPath: pathToUnityExe) || !pathToUnityHub.contains("Unity.app/Contents/MacOS/Unity") else { return }
        self.pathToUnityExe = try self.findPathToUnityExe().path
    }
    
    private func findPathToUnityExe() throws -> URL {
        let contentsURL = URL(fileURLWithPath: "/Applications/Unity/Hub/Editor")
        guard FileManager.default.isDirectory(contentsURL) else {
            throw VCCCommandSettingError(description: "No Unity Editor found.")
        }
        let contents = try FileManager.default.contentsOfDirectory(at: contentsURL, includingPropertiesForKeys: nil)
        
        for content in contents where content.lastPathComponent.contains("2019") {
            let unityExecutableURL = content.appendingPathComponent("Unity.app/Contents/MacOS/Unity")
            
            if FileManager.default.isExecutableFile(atPath: unityExecutableURL.path) {
                return unityExecutableURL
            }
        }
        
        throw VCCCommandSettingError(description: "Cannot Find Unity Editor.")
    }
    
    private func reapplyDictionary() {
        self.pathToUnityExe = self.dictionary["pathToUnityExe"] as? String ?? ""
        self.pathToUnityHub = self.dictionary["pathToUnityHub"] as? String ?? ""

        let decoder = DictionaryDecoder()
        
        guard let usersRepos = self.dictionary["userRepos"] as? [[String: Any]] else { return }
        
        self.userRepos = usersRepos.compactMap{ try? decoder.decode(UserRepo.self, from: $0) }
    }

    
    init() {
        do {
            self.dictionary = try JSONSerialization.jsonObject(with: Data(contentsOf: settingURL), options: [.mutableContainers]) as! NSMutableDictionary
        } catch {
            self.dictionary = defauteSetting
        }
        
        self.reapplyDictionary()
    }
}

private let defauteSetting = [
    "pathToUnityExe": "",
    "pathToUnityHub": "/Applications/Unity Hub.app/Contents/MacOS/Unity Hub",
    "userProjects": [Any](),
    "unityEditors": [Any](),
    "defaultProjectPath": URL.homeDirectory.appendingPathComponent(".local/share/VRChatProjects").path,
    "lastUIState": 0,
    "skipUnityAutoFind": false,
    "userPackageFolders": [Any](),
    "windowSize": 0,
    "skipRequirements": false,
    "allowPii": false,
    "projectBackupPath": URL.homeDirectory.appendingPathComponent(".local/share/VRChatCreatorCompanion/Project Backups").path,
    "showPrereleasePackages": false,
    "selectedProviders": 3,
    "userRepos": [Any]()
] as NSMutableDictionary
