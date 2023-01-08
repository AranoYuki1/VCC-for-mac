//
//  Init.swift
//  VCCMac
//
//  Created by yuki on 2023/01/04.
//

import CoreUtil

final class ApplicationInitializer {
    @RestorableState("app.appmodel.initialized") private var appModelInitialized = false
    @RestorableState("app.appsuccessmodel.initialized") private var appSuccessModelInitialized = false
    
    func initialize(command: VPMCommand) -> Promise<Void, Error> {
        guard !appSuccessModelInitialized else { return .fullfill() }; appSuccessModelInitialized = true
        
        return command.updatePackage()
    }
    
    func initialize(appModel: AppModel) -> Promise<Void, Error> {
        guard !appModelInitialized else { return .fullfill() }; appModelInitialized = true
    
        try? appModel.commandSetting.autoFixPathToUnityHub()
        try? appModel.commandSetting.autoFixPathToUnityExe()
        
        return .fullfill()
    }
}
