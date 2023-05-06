//
//  AppModel.swift
//  DevToys
//
//  Created by yuki on 2022/01/29.
//

import CoreUtil

final class AppModel {
    let logger: Logger
    let loggerManager: LoggerManager
    let sidebarManager: SidebarManager
    let commandSetting: VCCCommandSetting
    
    enum AppearanceType: String {
        case useSystemSettings
        case lightMode
        case darkMode
    }
    @RestorableState("appearance") var appearanceType: AppearanceType = .useSystemSettings
    @RestorableState("tool") var toolIdentifier = ""
    @RestorableState("debug") var debug = false { willSet { sidebarManager.showDebugItems = newValue } }
    @RestorableState("localPackageURL") var localPackageURL = AppFileManager.makeDirectory("local_package")
    
    @Observable var tool: Tool = .project { didSet { toolIdentifier = tool.identifier } }
    
    let reloadPublisher = CurrentValueSubject<Void, Never>(())
    
    init(logger: Logger, loggerManager: LoggerManager, sidebarManager: SidebarManager, commandSetting: VCCCommandSetting) {
        self.logger = logger
        self.loggerManager = loggerManager
        self.sidebarManager = sidebarManager
        self.commandSetting = commandSetting
        
        self.tool = sidebarManager.toolForIdentifier(toolIdentifier) ?? .project
        self.sidebarManager.showDebugItems = self.debug
        
        self.commandSetting.appModel = self
    }
}

extension NSViewController {
    var appModel: AppModel! { self.chainObject as? AppModel }
    
    var appSuccessModel: AppSuccessModel? { self.state(.appSuccessModel) }
    var appFailureModel: AppFailureModel? { self.state(.appFailureModel) }
    
    var appSuccessModelPublisher: some Publisher<AppSuccessModel, Never> {
        self.statePublisher(of: .appSuccessModel)
    }
    var appFailureModelPublisher: some Publisher<AppFailureModel, Never> {
        self.statePublisher(of: .appFailureModel)
    }
}

extension StateChannel {
    static var appSuccessModel: StateChannel<AppSuccessModel> { .init("AppSuccessModel") }
    static var appFailureModel: StateChannel<AppFailureModel> { .init("AppFailureModel") }
}
