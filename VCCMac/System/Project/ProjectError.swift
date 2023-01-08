//
//  ProjectError.swift
//  VCCMac
//
//  Created by yuki on 2023/01/02.
//

import Foundation

enum ProjectError: LocalizedError {
    case loadFailed(String)
    case migrateFailed(String)
    case projectOpenFailed
    
    var errorDescription: String {
        switch self {
        case .loadFailed(let message): return message
        case .migrateFailed(let message): return message
        case .projectOpenFailed: return "Fail to open a project."
        }
    }
}
