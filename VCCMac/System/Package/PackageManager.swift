//
//  PackageManager.swift
//  VCCMac
//
//  Created by yuki on 2023/01/01.
//

import CoreUtil

final class PackageManager {
    let command: VPMCommand
    let logger: Logger
    let manifestCoder: ProjectManifestCoder
    
    private let repogitoryLoader: RepogitoryLoader
    private let officialRepogitory: Promise<RepogitoryJSON, Error>
    private let curatedRepogitory: Promise<RepogitoryJSON, Error>
    
    init(command: VPMCommand, manifestCoder: ProjectManifestCoder, logger: Logger) {
        self.command = command
        self.manifestCoder = manifestCoder
        self.logger = logger
        
        let repogitoryLoader = RepogitoryLoader()
        self.repogitoryLoader = repogitoryLoader
        
        
        self.officialRepogitory = repogitoryLoader
            .load(URL.homeDirectory.appendingPathComponent("/.local/share/VRChatCreatorCompanion/Repos/vrc-official.json"))
        self.curatedRepogitory = repogitoryLoader
            .load(URL.homeDirectory.appendingPathComponent("/.local/share/VRChatCreatorCompanion/Repos/vrc-curated.json"))
    }
    
    func installedPackages(for project: Project) -> Promise<[Package], Error> {
        asyncHandler{[self] wait in
            guard let manifest = project.manifest else {
                logger.debug("Cannot Manipulate Packages of Legacy Project."); return []
            }
            var packages = [Package]()
            
            for package in try wait | getOfficialPackages() {
                if manifest.locked.keys.contains(where: { $0 == package.versions[0].name }) {
                    packages.append(package)
                }
            }
            
            for package in try wait | getCuratedPackages() {
                if manifest.locked.keys.contains(where: { $0 == package.versions[0].name }) {
                    packages.append(package)
                }
            }
            
            return packages
        }
    }
    
    func removePackage(_ package: Package, from project: Project) -> Promise<Void, Error> {
        guard let manifest = project.manifest else {
            logger.debug("Cannot Manipulate Packages of Legacy Project.")
            return .fullfill()
        }

        return Promise.tryAsync{ () -> Promise<Void, Error> in
            guard let projectURL = project.projectURL else { return .fullfill() }
            
            let topVersion = package.versions[0]
            let identifier = topVersion.name
            
            let packageFileURL = projectURL.appendingPathComponent("Packages/\(identifier)")
            try FileManager.default.removeItem(at: packageFileURL)
            
            var manifest = manifest
            manifest.dependencies.removeValue(forKey: identifier)
            manifest.locked.removeValue(forKey: identifier)
            try self.manifestCoder.writeManifest(manifest, projectURL: projectURL)
            return project.reload()
        }
        .flatMap{ $0 }
    }
    
    func addPackage(_ package: PackageVersion, to project: Project) -> Promise<Void, Error> {
        guard let projectURL = project.projectURL else { return .fullfill() }
        
        return command.addPackage(package, to: projectURL)
            .flatPeek{ project.reload() }
    }
    
    func getOfficialPackages() -> Promise<[Package], Error> {
        self.officialRepogitory.tryMap{
            try $0.packageList.map{ try self.model(for: $0) }
        }
    }
    
    func getCuratedPackages() -> Promise<[Package], Error> {
        self.curatedRepogitory.tryMap{
            try $0.packageList.map{ try self.model(for: $0) }
        }
    }
    
    private func model(for package: PackageJSON) throws -> Package {
        let versions = package.versions.sorted(by: { key, _ in key }).map{ $0.value }
        guard !versions.isEmpty else { throw PackageError.noVersions }
        return Package(
            versions: versions,
            displayName: versions[0].displayName,
            selectedVersion: versions[0]
        )
    }
}


final class Package {
    let versions: [PackageVersion]
    let displayName: String
    
    @Observable var selectedVersion: PackageVersion
    
    init(versions: [PackageVersion], displayName: String, selectedVersion: PackageVersion) {
        self.versions = versions
        self.displayName = displayName
        self.selectedVersion = selectedVersion
    }
}

private struct RepogitoryJSON: Codable {
    let name: String
    let author: String
    let url: URL
    let packages: [String: PackageJSON]
    
    var packageList: [PackageJSON] {
        self.packages.values.sorted(by: { $0.displayName })
    }
}

private struct PackageJSON: Codable {
    let versions: [String: PackageVersion]
    var displayName: String { versions.values.first?.displayName ?? "No Name" }
}

final class PackageVersion: Codable {
    let name: String
    let displayName: String
    let version: String
    let unity: String?
    let description: String
    let repo: URL
    let url: URL
}

final private class RepogitoryLoader {
    private static let decoder = JSONDecoder()
    
    func load(_ localRepogitoryURL: URL) -> Promise<RepogitoryJSON, Error> {
        struct LocalFile: Codable {
            let repo: RepogitoryJSON
        }
        
        return .tryAsync{
            let data = try Data(contentsOf: localRepogitoryURL)
            return try Self.decoder.decode(LocalFile.self, from: data).repo
        }
    }
}

enum PackageError: Error, CustomStringConvertible {
    case noVersions
    
    var description: String {
        switch self {
        case .noVersions: return "No versions"
        }
    }
}
