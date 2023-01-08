//
//  VPMCatalyst.swift
//  VCCMac
//
//  Created by yuki on 2022/12/22.
//

import Foundation
import Promise

final class VPMCatalyst: CommandCatalyst {
    let executableURL: URL
    let logger: Logger
    
    init(logger: Logger) {
        self.logger = logger
        self.executableURL = URL.homeDirectory.appending(path: ".dotnet/tools/vpm")
    }
}
