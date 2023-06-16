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
        
        self.startRepositoryLoad()
    }
    
    func addRepogitory(_ url: URL) -> Promise<Void, Never> {
        self.command.addRepo(url).catch(by: logger)
            .finally{ try? self.vccSetting.reload() }
    }
    
    func removeRepogitory(_ id: String) {
        self.command.removeRepo(id).catch(by: logger)
            .finally{
                try? self.vccSetting.reload()
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

        return Promise.tryAsync{ () -> Promise<Void, Error> in
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
        
    private func startRepositoryLoad() {
        let repogitoryLoader = RepogitoryLoader()
        
        let officialRepoURL = URL.homeDirectory.appendingPathComponent("/.local/share/VRChatCreatorCompanion/Repos/vrc-official.json")
        let curatedRepoURL = URL.homeDirectory.appendingPathComponent("/.local/share/VRChatCreatorCompanion/Repos/vrc-curated.json")
        
        let repos = self.vccSetting.$userRepos
            .map{ [officialRepoURL, curatedRepoURL] + $0.map{ URL(fileURLWithPath: $0.localPath) } }
            .map{
                return $0.map{ repogitoryLoader.load($0) }.combineAll().publisher()
            }.switchToLatest()
            .tryMap{[self] repos in
                var repogitories = [Repogitory]()
                for (i, repo) in repos.enumerated() {
                    let r = Repogitory(
                        meta: repo, packages: try repo.packageList.map{ try createPackage(for: $0) }
                    )
                    if i >= 2 {
                        r.isUserRepo = true
                    }
                    repogitories.append(r)
                }
                return repogitories
            }
        
        repos
            .catch{
                self.logger.error("\($0)")
                return Just([PackageManager.Repogitory]())
            }
            .sink{
                self.repos = $0
            }
            .store(in: &objectBag)
    }
    
    private func createPackage(for package: PackageContainerJSON) throws -> Package {
        let versions = package.versions.sorted(by: { key, _ in key }).map{ $0.value }
        guard !versions.isEmpty else { throw PackageError.noVersions }
        
        let package = Package(versions: versions, displayName: versions[0].displayName, selectedVersion: versions[0])
        self.packageTable[versions[0].name] = package
        return package
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

final class Package {
    let versions: [PackageJSON]
    let displayName: String
    var localPackageURL: URL?
    
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

final class PackageJSON: Codable {
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
