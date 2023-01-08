//
//  Project+UI.swift
//  VCCMac
//
//  Created by yuki on 2022/12/30.
//

import CoreUtil

private let formatter = DateFormatter() => {
    $0.doesRelativeDateFormatting = true
    $0.dateStyle = .medium
    $0.timeStyle = .short
}

extension Project {
    var formattedDatep: some Publisher<String, Never> {
        self.$accessDate.map{ formatter.string(from: $0) }.receive(on: DispatchQueue.main)
    }
}

extension VPMTemplate {
    var projectType: ProjectType {
        switch self.name {
        case "Avatar": return .avatarVPM
        case "World": return .worldVPM
        case "Base": return .baseVPM
        case "UdonSharp": return .udonSharpVPM
        default: return .community
        }
    }
    
    var priority: Int {
        switch self.name {
        case "Avatar": return 5
        case "World": return 6
        case "UdonSharp": return 7
        case "Base": return 8
        default: return 100
        }
    }
}

extension ProjectType {
    var icon: NSImage {
        switch self {
        case .legacyBase: return R.image.project.base()
        case .legacyAvatar: return R.image.project.avatar()
        case .legacyWorld: return R.image.project.world()
        case .legacyUdonSharp: return R.image.project.usharp()
            
        case .udonSharpVPM: return R.image.project.usharp()
        case .avatarVPM: return R.image.project.avatar()
        case .worldVPM: return R.image.project.world()
        case .baseVPM: return R.image.project.base()
            
        case .community: return R.image.project.commnity()
        case .unkown: return R.image.project.unkown()
        case .notUnityProject: return R.image.project.error()
        }
    }
    
    var isLegacy: Bool {
        switch self {
        case .legacyBase, .legacyAvatar, .legacyWorld, .legacyUdonSharp: return true
        default: return false
        }
    }
    
    var color: NSColor {
        switch self {
        case .legacyBase: return .systemOrange
        case .legacyAvatar: return .systemPink
        case .legacyWorld: return .systemBlue
        case .legacyUdonSharp: return .systemGreen
            
        case .udonSharpVPM: return .systemOrange
        case .avatarVPM: return .systemPink
        case .worldVPM: return .systemBlue
        case .baseVPM: return .systemGreen
            
        case .community: return .systemPurple
        case .unkown: return .systemYellow
        case .notUnityProject: return .systemRed
        }
    }
    
    var title: String {
        switch self {
        case .baseVPM: return R.localizable.base()
        case .avatarVPM: return R.localizable.avatar()
        case .worldVPM: return R.localizable.world()
        case .udonSharpVPM: return R.localizable.worldU()
            
        case .legacyBase: return R.localizable.baseLegacy()
        case .legacyAvatar: return R.localizable.avatarLegacy()
        case .legacyWorld: return R.localizable.worldLegacy()
        case .legacyUdonSharp: return R.localizable.udonSharpLegacy()
            
        case .community: return R.localizable.community()
        case .unkown(let type): return R.localizable.unkown(type)
        case .notUnityProject: return R.localizable.errorProject()
        }
    }
}

