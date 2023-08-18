//
//  ProjectMenuMeke.swift
//  VCCMac
//
//  Created by yuki on 2022/12/31.
//

import CoreUtil

extension AppSuccessModel {
    func addRepogitory(_ url: URL) {
        let toast = Toast(message: "レポジトリを追加しています...")
        toast.addSpinningIndicator()
        self.packageManager.addRepogitory(url)
            .receive(on: .main)
            .finally{
                toast.close()
            }
        toast.show(.whileDeinit)
    }
    
    
    func modalNewProject() -> Promise<Void, Error> {
        guard let window = NSApp.mainWindow else { appModel.logger.debug("No window."); return .resolve() }
        
        let model = ProjectTempleteSelectModel(command: self.command, projectManager: self.projectManager, logger: appModel.logger)
        let modal = ProjectTempleteSelectWindow(model: model)
               
        let promise = Promise<Void, Error>()
        
        window.beginSheet(modal) {[self] in
            guard $0 == .OK else { return }
         
            guard let templete = model.selectedTemplate else { return appModel.logger.debug("No templete selected.") }
                    
            let savePanel = NSSavePanel()
            savePanel.beginSheetModal(for: window) {
                guard $0 == .OK, let url = savePanel.url else { return }
                
                let title = url.lastPathComponent
                let baseURL = url.deletingLastPathComponent()
                
                let toast = Toast(message: R.localizable.creatingProject())
                toast.addSpinningIndicator()
                toast.show(.whileDeinit)
                
                self.projectManager.createProject(title: title, templete: templete, at: baseURL)
                    .receive(on: .main)
                    .finally{
                        toast.close()
                        Toast(message: R.localizable.projectCreated()).show()
                    }
                    .subscribe(promise.resolve, promise.reject)
            }
        }
        
        return promise
    }
    
    func modalOpenProject() -> Promise<Void, Error> {
        guard let window = NSApp.mainWindow else { appModel.logger.debug("No window."); return .resolve() }
        
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = true
        // AppKitのバグです。
        openPanel.setValue(["zip"] as NSArray, forKey: "allowedFileTypes")
              
        let promise = Promise<Void, Error>()
        openPanel.beginSheetModal(for: window) {
            defer { promise.resolve() }
            guard $0 == .OK, let url = openPanel.url else { return }
            self.addProject(at: url)
        }
        return promise
    }
    
    func addProject(at url: URL) {
        func addZip() -> Promise<Void, Error> {
            let openPanel = NSOpenPanel()
            openPanel.message = R.localizable.selectAFolderToUnpackBackup()
            openPanel.canChooseFiles = false
            openPanel.canChooseDirectories = true
            openPanel.canCreateDirectories = true
            let promise = Promise<Void, Error>()
            openPanel.beginSheetModal(for: NSApp.mainWindow!) {
                guard $0 == .OK, let unpackURL = openPanel.url else { return }
                
                let progress = Progress()
                
                let toast = Toast(message: R.localizable.unpackingBackup())
                toast.addSpinningProgressIndicator(progress)
                toast.show(.whileDeinit)

                self.projectManager.addBackupProject(url, unpackTo: unpackURL, unpackProgress: progress)
                    .receive(on: .main)
                    .peek{
                        toast.close()
                        Toast(message: R.localizable.unpackBackupDone()).show()
                    }
                    .subscribe(promise.resolve, promise.reject)
            }
            return promise
        }
        
        func addProject() -> Promise<Void, Error> {
            if url.pathExtension == "zip" {
                return addZip()
            } else if FileManager.default.isDirectory(url) {
                return self.projectManager.addProject(url).receive(on: .main)
            } else {
                return .reject(ProjectError.loadFailed("Unkown Project Load Type."))
            }
        }
        
        addProject()
            .catch{[self] error in
                logger.debug(error)
                logger.error(R.localizable.addProjectFailed())
            }
    }
    
    func backupProject(_ project: Project) {
        guard let projectURL = project.projectURL else { return }
        
        let modal = NSSavePanel()
        modal.nameFieldLabel = R.localizable.backupName()
        modal.nameFieldStringValue = projectURL.lastPathComponent + ".zip"
        modal.beginSheetModalPromise(for: NSApp.mainWindow!).eraseToError()
            .flatMap{
                guard $0 == .OK, let url = modal.url else { return .resolve() }
                return self.projectManager.backupProject(project, to: url)
            }
            .catch{[self] error in
                logger.debug(error)
                logger.error(R.localizable.backupProjectFailed())
            }
    }
    
    @discardableResult
    func reloadProject(_ project: Project) -> Promise<Void, Never> {
        project.reload()
            .catch{[self] error in
                logger.debug(error)
                logger.error(R.localizable.reloadProjectFailed())
            }
    }
    
    func openProjectInFinder(_ project: Project) {
        guard let projectURL = project.projectURL else { return logger.error(R.localizable.cannotFindProject()) }
        NSWorkspace.shared.selectFile(projectURL.path, inFileViewerRootedAtPath: projectURL.deletingLastPathComponent().path)
    }
    
    @discardableResult
    func unlinkProject(_ project: Project) -> Promise<Void, Never> {
        self.projectManager.unlinkProject(project).receive(on: .main)
            .peek{[self] in
                if self.selectedProject === project { self.selectedProject = nil }
            }
    }
    
    func renameProject(_ project: Project) {
        
        let model = ProjectRenameModel(project: project)
        let modal = ProjectRenameWindow(model: model)
            
        NSApp.mainWindow?.beginSheetPromise(modal).eraseToError()
            .flatMap{
                guard $0 == .OK, !model.title.isEmpty else { return .resolve() }
                return self.projectManager.renameProject(project, to: model.title)
            }
            .catch{[self] error in
                logger.debug(error)
                logger.error(R.localizable.renameProjectFailed())
            }
        
    }
    
    func deleteProject(_ project: Project) {
        let alert = NSAlert()
        alert.messageText = R.localizable.doYouWantToMoveProjectToTheTrashOrOnlyRemoveTheReferenceToIt(project.title)
        alert.informativeText = R.localizable.thisOperationCannotBeUndone()
        alert.addButton(withTitle: R.localizable.moveToTrash()).keyEquivalent = ""
        alert.addButton(withTitle: R.localizable.removeReference()).keyEquivalent = "\r"
        alert.addButton(withTitle: R.localizable.cancel())
        
        let res = alert.runModal()
        
        switch res {
        case .alertFirstButtonReturn: self.trashProject(project)
        case .alertSecondButtonReturn: self.unlinkProject(project)
        default:
            return
        }
    }
    
    func makeProjectMenu(for project: Project) -> [NSMenuItem] {
        [
            NSMenuItem(title: R.localizable.showInFinder()) { self.openProjectInFinder(project) },
            NSMenuItem.separator(),
            NSMenuItem(title: R.localizable.moveToTrash()) { self.deleteProject(project) },
            NSMenuItem(title: R.localizable.unlink()) { self.unlinkProject(project) },
            NSMenuItem.separator(),
            NSMenuItem(title: R.localizable.reload()) { self.reloadProject(project) },
            NSMenuItem(title: R.localizable.rename()) { self.renameProject(project) },
            NSMenuItem(title: R.localizable.backupProject(project.title)) { self.backupProject(project) },
        ]
    }
    
    @discardableResult
    private func trashProject(_ project: Project) -> Promise<Void, Never> {
        guard let projectURL = project.projectURL else {
            logger.debug("Missing projectURL"); return .resolve()
        }

        
        return self.projectManager.unlinkProject(project)
            .receive(on: .main)
            .peek{[self] in
                NSWorkspace.shared.recycle([projectURL]) {[self] _, error in
                    if let error = error {
                        logger.log("\(error)")
                        logger.error(R.localizable.removeProjectFailed())
                    } else {
                        NSSound.dragToTrash?.play()
                    }
                    
                    if self.selectedProject === project {
                        self.selectedProject = nil
                    }
                }
            }
    }
}

extension NSSound {
    static let dragToTrash = NSSound(contentsOfFile: "/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/dock/drag to trash.aif", byReference: true)
}

extension NSWindow {
    public func beginSheetPromise(_ sheetWindow: NSWindow) -> Promise<NSApplication.ModalResponse, Never> {
        Promise{ resolve, _ in
            self.beginSheet(sheetWindow, completionHandler: resolve)
        }
    }
    
    public func beginCriticalSheetPromise(_ sheetWindow: NSWindow) -> Promise<NSApplication.ModalResponse, Never> {
        Promise{ resolve, _ in
            self.beginCriticalSheet(sheetWindow, completionHandler: resolve)
        }
    }
}

extension NSSavePanel {
    public func beginSheetModalPromise(for sheetWindow: NSWindow) -> Promise<NSApplication.ModalResponse, Never> {
        Promise{ resolve, _ in
            self.beginSheetModal(for: sheetWindow, completionHandler: resolve)
        }
    }
    
    public func beginPromise() -> Promise<NSApplication.ModalResponse, Never> {
        Promise{ resolve, _ in
            self.begin(completionHandler: resolve)
        }
    }
}
