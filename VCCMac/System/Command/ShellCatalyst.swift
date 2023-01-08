//
//  ShellCatalyst.swift
//  VCCMac
//
//  Created by yuki on 2023/01/04.
//

import CoreUtil

final class ShellCatalyst: CommandCatalyst {
    let executableURL: URL
    let logger: Logger
    
    init(logger: Logger) {
        self.executableURL = URL(filePath: "/bin/sh")
        self.logger = logger
    }
}

