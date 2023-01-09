//
//  UnityCatalyst.swift
//  VCCMac
//
//  Created by yuki on 2022/12/26.
//

import CoreUtil

final class UnityCatalyst: CommandCatalyst {
    let executableURL: URL
    let logger: Logger
    
    init(executableURL: URL, logger: Logger) {
        self.executableURL = executableURL
        self.logger = logger
    }
}
