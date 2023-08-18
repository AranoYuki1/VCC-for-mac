//
//  AppWindowController.swift
//  DevToys
//
//  Created by yuki on 2022/01/29.
//

import CoreUtil
import Darwin
import AppKit

final class AppWindowController: NSWindowController {
    private var splitViewController: NSSplitViewController {
        self.window?.contentViewController as! NSSplitViewController
    }
    
    @objc private func toggleSidebar() {
        splitViewController.splitViewItems[0].animator().isCollapsed.toggle()
    }

    override func windowDidLoad() {
        let loggerManager = LoggerManager(maxLogCount: 20)
        let logger = self.makeLogger(loggerManager)
        let commandSetting = VCCCommandSetting()
        let appModel = AppModel(logger: logger, loggerManager: loggerManager, sidebarManager: .shared, commandSetting: commandSetting)
        
        // connect appearance
        appModel.$appearanceType
            .sink{[unowned self] in
                switch $0 {
                case .useSystemSettings: self.window?.appearance = nil
                case .darkMode: self.window?.appearance = NSAppearance(named: .darkAqua)
                case .lightMode: self.window?.appearance = NSAppearance(named: .aqua)
                }
            }
            .store(in: &objectBag)
        
        // connect sidebar
        appModel.$tool
            .sink{[unowned self] in self.window?.title = $0.title }
            .store(in: &objectBag)
        
        // load system
        self.loadSystem(logger, appModel: appModel)
            .catch{ logger.debug($0) }
        
        #if DEBUG
        ConsoleWindow.shared.show()
        #endif
    }
    
    private func makeLogger(_ loggerManager: LoggerManager) -> Logger {
        let logger = Logger()
        
        logger.subscribe(level: .error) { log in
            DispatchQueue.main.async { Toast(message: log.message, color: .systemRed).show() }
        }
        logger.subscribe(level: .warn) { log in
            DispatchQueue.main.async { Toast(message: log.message, color: .systemYellow).show() }
        }
        logger.subscribe(level: .info) { log in
            DispatchQueue.main.async { Toast(message: log.message).show() }
        }
        
        #if DEBUG
        logger.subscribe(level: .log) { log in
            DispatchQueue.main.async { Toast(message: log.message, color: .systemGray).show() }
        }
        
        logger.subscribe(level: .debug, fileHandle: FileHandle.standardOutput)
        #endif
        
        logger.subscribe(level: .debug) { log in
            DispatchQueue.main.async { ConsoleWindow.shared.append(log) }
        }
        
        do {
            try loggerManager.setup(logger)
        } catch {
            print("Make application logger failed.")
        }
        
        return logger
    }
        
    private func loadSystem(_ logger: Logger, appModel: AppModel) -> Promise<Void, Error> {
        self.contentViewController?.chainObject = appModel

        let catalyst = VPMCatalyst(logger: logger)
        let command = VPMCommand(catalyst: catalyst)
        
        let initializer = ApplicationInitializer()
        
        return initializer.initialize(appModel: appModel).combine(initializer.initialize(command: command))
        .receive(on: .main)
        .tryPeek{ _ in
            let containerDirectoryURL = AppFileManager.makeDirectory("projects")

            let manifestCoder = ProjectManifestCoder(logger: logger)
            let projectManager = ProjectManager(command: command, containerDirectoryURL: containerDirectoryURL, manifestCoder: manifestCoder, logger: logger)
            let packageManager = PackageManager(command: command, logger: logger, vccSetting: appModel.commandSetting, manifestCoder: manifestCoder)
            
            appModel.reloadPublisher
                .receive(on: DispatchQueue.main)
                .sink{[unowned self] in
                    _ = self.reloadRequirement(
                        command: command, appModel: appModel, packageManager: packageManager, projectManager: projectManager, logger: logger
                    )
                }
                .store(in: &self.objectBag)
        }
        .eraseToVoid()
    }
    
    private func reloadRequirement(command: VPMCommand, appModel: AppModel, packageManager: PackageManager, projectManager: ProjectManager, logger: Logger) -> Promise<Void, Never> {
        assert(Thread.isMainThread)
        guard let contentViewController = self.contentViewController else { return .resolve() }
        
        return VPMRequirementChecker(appModel: appModel, command: command).failureReasons().receive(on: .main).map{ reasons in
            if reasons.isEmpty {
                if contentViewController.state(.appSuccessModel) == nil {
                    _ = projectManager.reloadProjects()
                    let model = AppSuccessModel(appModel: appModel, command: command, projectManager: projectManager, packageManager: packageManager, logger: logger)
                    contentViewController.setState(model, of: .appSuccessModel)
                    contentViewController.setState(nil, of: .appFailureModel)
                }
            } else {
                let model = AppFailureModel(reasons: reasons, appModel: appModel, logger: logger)
                contentViewController.setState(model, of: .appFailureModel)
                contentViewController.setState(nil, of: .appSuccessModel)
            }
        }
    }
}
