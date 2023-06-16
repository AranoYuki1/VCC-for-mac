//
//  AppSuccessModel.swift
//  VCCMac
//
//  Created by yuki on 2023/01/02.
//

import CoreUtil

enum ProjectLegacyFilterType: String, TextItem {
    case all
    case vpm
    case legacy
    
    var title: String {
        switch self {
        case .all: return R.localizable.all()
        case .vpm: return R.localizable.vpM()
        case .legacy: return R.localizable.legacy()
        }
    }
}

enum ProjectFilterType: String, TextItem {
    case all
    case avatar
    case world
    case udonsharp
    
    var title: String {
        switch self {
        case .all: return R.localizable.all()
        case .avatar: return R.localizable.avatar()
        case .world: return R.localizable.world()
        case .udonsharp: return R.localizable.u()
        }
    }
}

extension ProjectLegacyFilterType {
    func accepts(_ type: ProjectType) -> Bool {
        switch self {
        case .all: return true
        case .vpm: return !type.isLegacy
        case .legacy: return type.isLegacy
        }
    }
}

extension ProjectFilterType {
    func accepts(_ type: ProjectType) -> Bool {
        switch self {
        case .all: return true
        case .avatar: return type == .avatarVPM || type == .legacyAvatar
        case .world: return type == .worldVPM || type == .legacyWorld
        case .udonsharp: return type == .udonSharpVPM || type == .legacyUdonSharp
        }
    }
}

final class AppSuccessModel {
    let appModel: AppModel
    let command: VPMCommand
    let projectManager: ProjectManager
    let packageManager: PackageManager
    let localPackageManager: LocalPackageManager
    let logger: Logger
    
    @Observable var selectedProject: Project?
    @RestorableState("filter") var filterType: ProjectFilterType = .all
    @RestorableState("filterlegacy") var legacyFilterType: ProjectLegacyFilterType = .all
    @RestorableState("migration.copy") var copyMigration = true
    @RestorableState("repo.index") var repoIndex: SelectedRepo = .installed
    
    enum SelectedRepo: RawRepresentable {
        case installed
        case local(Int)
        
        var rawValue: Int {
            switch self { case .installed: return -1 case .local(let index): return index }
        }
        init(rawValue: Int) {
            if rawValue == -1 { self = .installed } else { self = .local(rawValue) }
        }
    }
    
    init(appModel: AppModel, command: VPMCommand, projectManager: ProjectManager, packageManager: PackageManager, logger: Logger) {
        self.appModel = appModel
        self.command = command
        self.projectManager = projectManager
        self.packageManager = packageManager
        self.logger = logger
        
        self.localPackageManager = LocalPackageManager(appModel: appModel)
    }
}

extension AppSuccessModel {
    var selectedRepo: some Publisher<PackageManager.Repogitory, Never> {
        self.$repoIndex
            .map{
                switch $0 {
                case .installed:
                    return self.$selectedProject
                        .compactMap{ $0 }
                        .map{ self.packageManager.installedPackages(for: $0).publisher() }
                        .switchToLatest()
                        .eraseToAnyPublisher()
                case .local(let index):
                    return self.packageManager.$repos
                        .compactMap{ array in
                            if array.indices.contains(index) {
                                return array[index]
                            }
                            self.repoIndex = .installed
                            return nil
                        }
                        .eraseToAnyPublisher()
                }
            }
            .switchToLatest()
    }
}
