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
    let logger: Logger
    
    @Observable var selectedProject: Project?
    @RestorableState("filter") var filterType: ProjectFilterType = .all
    @RestorableState("filterlegacy") var legacyFilterType: ProjectLegacyFilterType = .all
    @RestorableState("repo") var selectedRepo: RepoType = .official
    
    init(appModel: AppModel, command: VPMCommand, projectManager: ProjectManager, packageManager: PackageManager, logger: Logger) {
        self.appModel = appModel
        self.command = command
        self.projectManager = projectManager
        self.packageManager = packageManager
        self.logger = logger
    }
}

