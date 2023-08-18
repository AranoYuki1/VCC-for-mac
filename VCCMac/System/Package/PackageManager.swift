//
//  PackageManager.swift
//  VCCMac
//
//  Created by yuki on 2023/01/01.
//

import CoreUtil

final class PackageManager {
    let command: VPMCommand
    let vccSetting: VCCCommandSetting
    let logger: Logger
    let manifestCoder: ProjectManifestCoder
    
    @Observable
    var repos: [Repogitory] = []
    
    private var packageTable = [String: Package]()
    private var objectBag = Set<AnyCancellable>()
    
    init(command: VPMCommand, logger: Logger, vccSetting: VCCCommandSetting, manifestCoder: ProjectManifestCoder) {
        self.command = command
        self.logger = logger
        self.vccSetting = vccSetting
        self.manifestCoder = manifestCoder
        
        _ = self.reloadRepositories()
    }
    
    func findPackage(for name: String) -> Package? {
        packageTable[name]
    }
    
    func checkForUpdate() -> Promise<Void, Error> {
        self.repos.compactMap{ $0.url }
            .map{ self.command.listRepo($0) }
            .combineAll()
            .eraseToVoid()
            .flatMap{_ in self.reloadRepositories().eraseToError() }
            .eraseToVoid()
    }
    
    func addRepogitory(_ url: URL) -> Promise<Void, Never> {
        self.command.addRepo(url).catch(by: logger)
            .receive(on: .main)
            .finally{
                try? self.vccSetting.reload()
                _ = self.reloadRepositories()
            }
    }
    
    func removeRepogitory(_ id: String) -> Promise<Void, Never> {
        self.command.removeRepo(id).catch(by: logger)
            .receive(on: .main)
            .finally{
                try? self.vccSetting.reload()
                _ = self.reloadRepositories()
            }
    }
    
    func installedPackages(for project: Project) -> Promise<Repogitory, Never> {
        guard let manifest = project.manifest else {
            logger.debug("Cannot Manipulate Packages of Legacy Project."); return .resolve(.init(packages: [], name: "error", id: "error"))
        }
        
        return $repos.filter{ !$0.isEmpty }.firstValue()
            .map{_ in
                Repogitory(
                    packages: manifest.locked.keys.compactMap{ self.packageTable[$0] },
                    name: "Installed",
                    id: "com.yuki.installed"
                )
            }
    }
    
    func removePackage(_ package: Package, from project: Project) -> Promise<Void, Error> {
        guard let manifest = project.manifest else {
            logger.debug("Cannot Manipulate Packages of Legacy Project.")
            return .resolve()
        }

        return Promise.tryDispatch{ () -> Promise<Void, Error> in
            guard let projectURL = project.projectURL else { return .resolve() }
            
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
    
    func addPackage(_ package: PackageJSON, to project: Project) -> Promise<Void, Error> {
        guard let projectURL = project.projectURL else { return .resolve() }
        
        return command.addPackage(package, to: projectURL)
            .flatPeek{ project.reload() }
    }
        
    private func reloadRepositories() -> Promise<Void, Never> {
        let repogitoryLoader = RepogitoryLoader()
        
        let officialRepoURL = URL.homeDirectory.appendingPathComponent("/.local/share/VRChatCreatorCompanion/Repos/vrc-official.json")
        let curatedRepoURL = URL.homeDirectory.appendingPathComponent("/.local/share/VRChatCreatorCompanion/Repos/vrc-curated.json")
                
        func createPackage(for package: PackageContainerJSON) throws -> Package {
            let versions = package.versions.map{ $0.value }.sorted(by: {
                $0.version.compare($1.version) == .orderedDescending
            })
            guard !versions.isEmpty else { throw PackageError.noVersions }
            
            let package = Package(versions: versions, displayName: versions[0].displayName, selectedVersion: versions[0])
            self.packageTable[versions[0].name] = package
            return package
        }
        
        func loadRepo(_ url: URL, isUserRepo: Bool) -> Promise<Repogitory, Error> {
            Promise{
                let meta = try await repogitoryLoader.load(url).value
                let repo = Repogitory(
                    meta: meta, packages: try meta.packageList.map{ try createPackage(for: $0) }
                )
                repo.isUserRepo = isUserRepo
                
                return repo
            }
        }
        
        var repos = [Promise<Repogitory, Error>]()
        
        repos.append(loadRepo(officialRepoURL, isUserRepo: false))
        repos.append(loadRepo(curatedRepoURL, isUserRepo: false))
        
        for repo in vccSetting.userRepos {
            repos.append(loadRepo(URL(fileURLWithPath: repo.localPath), isUserRepo: true))
        }
        
        return repos.combineAll()
            .replaceError{
                self.logger.error($0)
                return []
            }
            .peek{ self.repos = $0 }
            .eraseToVoid()
    }
}

extension PackageManager {
    final class Repogitory {
        let packages: [Package]
        
        let name: String
        let author: String?
        let id: String
        let url: URL?
        
        fileprivate(set) var isUserRepo: Bool = false
        
        fileprivate init(meta: RepogitoryJSON, packages: [Package]) {
            self.packages = packages
            self.name = meta.name
            self.author = meta.author
            self.id = meta.id
            self.url = meta.url
        }
        
        fileprivate init(packages: [Package], name: String, id: String, author: String? = nil,  url: URL? = nil) {
            self.packages = packages
            self.name = name
            self.id = id
            self.author = author
            self.url = url
        }
    }
}

final class Package: CustomStringConvertible {
    let versions: [PackageJSON]
    let displayName: String
    var localPackageURL: URL?
    
    var description: String {
        return "Package(\(self.displayName), \(versions))"
    }
    
    @Observable var selectedVersion: PackageJSON
    
    init(version: PackageJSON) {
        self.displayName = version.displayName
        self.versions = [version]
        self.selectedVersion = version
    }
    
    init(versions: [PackageJSON], displayName: String, selectedVersion: PackageJSON) {
        self.versions = versions
        self.displayName = displayName
        self.selectedVersion = selectedVersion
    }
}


private struct RepogitoryJSON: Codable {
    let name: String
    let author: String
    let url: URL
    let id: String
    let packages: [String: PackageContainerJSON]
    
    var packageList: [PackageContainerJSON] {
        self.packages.values.sorted(by: { $0.displayName })
    }
}

private struct PackageContainerJSON: Codable {
    var versions: [String: PackageJSON] = [:]
    var displayName: String { versions.values.first?.displayName ?? "No Name" }
}

struct PackageJSON: Codable {
    let name: String
    let displayName: String
    let version: String
    let description: String
    let url: URL
}

final private class RepogitoryLoader {
    private static let decoder = JSONDecoder()
    
    func load(_ localRepogitoryURL: URL) -> Promise<RepogitoryJSON, Error> {
        struct LocalFile: Codable {
            let repo: RepogitoryJSON
        }
                
        return .tryDispatch{
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
