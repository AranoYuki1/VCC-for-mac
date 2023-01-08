//
//  VPMInstallCommand.swift
//  VCCMac
//
//  Created by yuki on 2023/01/04.
//

import CoreUtil

final class VPMInstallCommand {
    let catalyst: ShellCatalyst
    
    init(catalyst: ShellCatalyst) { self.catalyst = catalyst }
    
    
    func installedVPM() -> Promise<Void, Error> {
        self.run("dotnet tool install --global vrchat.vpm.cli").eraseToVoid()
    }
    
    @discardableResult
    private func run(_ arguments: String) -> Promise<String, Error> {
        let command = """
        export PATH="/usr/local/bin":$PATH
        export PATH="/usr/local/sbin":$PATH
        export PATH="/usr/local/share/dotnet":$PATH
        export PATH="~/.dotnet/tools":$PATH
        
        \(arguments)
        """.split(separator: "\n").joined(separator: "; ")
        
        return self.catalyst.run(["-c", command])
    }
}
