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
    
    init(logger: Logger) {
        self.executableURL = URL(filePath: "/Applications/Unity/Hub/Editor/2019.4.31f1/Unity.app/Contents/MacOS/Unity")
        self.logger = logger
    }
}
