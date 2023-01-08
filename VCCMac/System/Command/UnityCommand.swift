//
//  UnityCommand.swift
//  VCCMac
//
//  Created by yuki on 2023/01/01.
//

import CoreUtil

final class UnityCommand {
    let catalyst: UnityCatalyst
    
    init(catalyst: UnityCatalyst) { self.catalyst = catalyst }
    
    func openProject(at url: URL) -> Promise<Void, Error> {
        catalyst.run(["-projectPath", url.path]).eraseToVoid()
    }
}
