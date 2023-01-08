//
//  VCCCommandSetting.swift
//  VCCMac
//
//  Created by yuki on 2023/01/04.
//

import CoreUtil

struct VCCCommandSettingError: Error, CustomStringConvertible {
    let description: String
}

final class VCCCommandSetting {
    @Observable var pathToUnityExe: String {
        didSet { self.dictionary["pathToUnityExe"] = pathToUnityExe; save() }
    }
    @Observable var pathToUnityHub: String {
        didSet { self.dictionary["pathToUnityExe"] = pathToUnityExe; save() }
    }
    
    let settingURL = URL.homeDirectory.appending(path: ".local/share/VRChatCreatorCompanion/settings.json")
    
    weak var appModel: AppModel?
    
    private var dictionary: NSMutableDictionary
    
    private func save() {
        try? JSONSerialization.data(withJSONObject: dictionary, options: [
            .prettyPrinted, .withoutEscapingSlashes, .sortedKeys
        ]).write(to: settingURL)
        
        appModel?.reloadPublisher.send()
    }
    
    public func autoFixPathToUnityHub() throws {
        guard !FileManager.default.isExecutableFile(atPath: pathToUnityHub) else { return }
        self.pathToUnityHub = "/Applications/Unity Hub.app/Contents/MacOS/Unity Hub"
    }
    
    public func autoFixPathToUnityExe() throws {
        guard !FileManager.default.isExecutableFile(atPath: pathToUnityExe) || !pathToUnityHub.contains("Unity.app/Contents/MacOS/Unity") else { return }
        self.pathToUnityExe = try self.findPathToUnityExe().path
    }
    
    private func findPathToUnityExe() throws -> URL {
        let contentsURL = URL(filePath: "/Applications/Unity/Hub/Editor")
        guard FileManager.default.isDirectory(contentsURL) else {
            throw VCCCommandSettingError(description: "No Unity Editor found.")
        }
        let contents = try FileManager.default.contentsOfDirectory(at: contentsURL, includingPropertiesForKeys: nil)
        
        for content in contents where content.lastPathComponent.contains("2019") {
            let unityExecutableURL = content.appending(component: "Unity.app/Contents/MacOS/Unity")
            
            if FileManager.default.isExecutableFile(atPath: unityExecutableURL.path) {
                return unityExecutableURL
            }
        }
        
        throw VCCCommandSettingError(description: "Cannot Find Unity Editor.")
    }
    
    init() {
        do {
            self.dictionary = try JSONSerialization.jsonObject(with: Data(contentsOf: settingURL), options: [.mutableContainers]) as! NSMutableDictionary
        } catch {
            self.dictionary = [
                "pathToUnityExe": "",
                "pathToUnityHub": "/Applications/Unity Hub.app/Contents/MacOS/Unity Hub",
                "userProjects": [],
                "unityEditors": [],
                "defaultProjectPath": "/Users/yuki/.local/share/VRChatProjects",
                "lastUIState": 0,
                "skipUnityAutoFind": false,
                "userPackageFolders": [],
                "windowSize": 0,
                "skipRequirements": false,
                "lastNewsUpdate": "2023-01-04T08:16:04.184519Z",
                "allowPii": false,
                "projectBackupPath": "/Users/yuki/.local/share/VRChatCreatorCompanion/Project Backups",
                "showPrereleasePackages": false,
                "selectedProviders": 3,
                "userRepos": []
            ]
        }
        
        self.pathToUnityExe = self.dictionary["pathToUnityExe"] as? String ?? ""
        self.pathToUnityHub = self.dictionary["pathToUnityHub"] as? String ?? ""
        
    }
}
