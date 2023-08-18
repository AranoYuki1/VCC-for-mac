//
//  LocalPackageManager.swift
//  VCCMac
//
//  Created by yuki on 2023/05/06.
//

import Foundation
import AppKit
import CoreUtil

final class LocalPackage {
    let packageJSON: PackageJSON
    let localURL: URL
    
    init(packageJSON: PackageJSON, localURL: URL) {
        self.packageJSON = packageJSON
        self.localURL = localURL
    }
}

final class LocalPackageManager {
    
    @Observable
    var packages = [LocalPackage]()
    
    private let appModel: AppModel
    
    init(appModel: AppModel) {
        self.appModel = appModel
        
        Promise.tryDispatch{ try self.listPackage() }
            .peek{ self.packages = $0 }
            .catch(by: appModel.logger)
    }
    
    private func listPackage() throws -> [LocalPackage] {
        let contents = try FileManager.default.contentsOfDirectory(at: appModel.localPackageURL, includingPropertiesForKeys: nil)
            
        var packages = [LocalPackage]()
        
        var errorPackages = [URL]()
        for content in contents {
            let packagePath = content.appendingPathComponent("package.json")
            
            do {
                let data = try Data(contentsOf: packagePath)
                let packageJSON = try JSONDecoder().decode(PackageJSON.self, from: data)
                packages.append(LocalPackage(packageJSON: packageJSON, localURL: content))
            } catch {
                errorPackages.append(content)
                continue
            }
        }
        
        if !errorPackages.isEmpty {
            NSWorkspace.shared.recyclePromise(errorPackages, playSoundEffect: true)
                .finally{
                    let packageNames = errorPackages.map{ $0.lastPathComponent }.joined(separator: ", ")
                    let message = "\(errorPackages.count) packages had errors and were removed. (\(packageNames))"
                    self.appModel.logger.warn(message)
                }
                .catch(by: appModel.logger)
        }
        
        return packages
    }
    
    func addPackage(source: URL) throws -> LocalPackage {
        let packagePath = source.appendingPathComponent("package.json")
        
        if !FileManager.default.fileExists(at: packagePath) {
            throw VPMError.checkFailed("Package.json does not exist.")
        }
        
        let data = try Data(contentsOf: packagePath)
        let packageJSON = try JSONDecoder().decode(PackageJSON.self, from: data)
        let localURL = appModel.localPackageURL.appendingPathComponent(packageJSON.name)
        
        if FileManager.default.fileExists(at: packagePath) {
            throw VPMError.checkFailed("This package is already installed.")
        }
        
        try FileManager.default.copyItem(at: source, to: localURL)
        
        let package = LocalPackage(packageJSON: packageJSON, localURL: localURL)
        self.packages.append(package)
        return package
    }
    
    func removePackage(_ package: LocalPackage) {
        NSWorkspace.shared.recyclePromise([package.localURL], playSoundEffect: true)
            .finally {
                self.packages.removeAll(where: { $0 === package })
            }
            .catch(by: self.appModel.logger)
    }
}
