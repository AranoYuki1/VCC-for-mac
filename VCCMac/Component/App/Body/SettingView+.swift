//
//  SettingView+.swift
//  DevToys
//
//  Created by yuki on 2022/02/16.
//

import CoreUtil

final class SettingViewController: NSViewController {
    private let cell = SettingView()
    
    override func loadView() { self.view = cell }
    
    override func chainObjectDidLoad() {
        self.appModel.$appearanceType
            .sink{[unowned self] in self.cell.appearancePicker.selectedItem = $0 }.store(in: &objectBag)
        self.appModel.$debug
            .sink{[unowned self] in self.cell.debugSwitch.state = $0 ? .on : .off }.store(in: &objectBag)
        
        self.cell.appearancePicker.itemPublisher
            .sink{[unowned self] in self.appModel.appearanceType = $0 }.store(in: &objectBag)
        self.cell.debugSwitch.actionPublisher
            .sink{[unowned self] in self.appModel.debug.toggle() }.store(in: &objectBag)
        
        self.appModel.commandSetting.$pathToUnityExe
            .sink{[unowned self] in self.cell.pathToUnityExeField.string = $0 }.store(in: &objectBag)
        self.appModel.commandSetting.$pathToUnityHub
            .sink{[unowned self] in self.cell.pathToUnityHubField.string = $0 }.store(in: &objectBag)
        
        self.cell.pathToUnityExeField.endEditingStringPublisher
            .sink{[unowned self] in appModel.commandSetting.pathToUnityExe = $0 }.store(in: &objectBag)
        self.cell.pathToUnityHubField.endEditingStringPublisher
            .sink{[unowned self] in appModel.commandSetting.pathToUnityHub = $0 }.store(in: &objectBag)
        
        self.cell.pathToUnityExeButton.actionPublisher
            .sink{[unowned self] in
                do { try appModel.commandSetting.autoFixPathToUnityExe() } catch { Toast(error: error).show() }
            }
            .store(in: &objectBag)
        self.cell.pathToUnityHubButton.actionPublisher
            .sink{[unowned self] in
                do { try appModel.commandSetting.autoFixPathToUnityHub() } catch { Toast(error: error).show() }
                
            }
            .store(in: &objectBag)
        self.cell.openSettingJoinButton.actionPublisher
            .sink{[unowned self] in
                NSWorkspace.shared.selectFile(
                    appModel.commandSetting.settingURL.path,
                    inFileViewerRootedAtPath: appModel.commandSetting.settingURL.deletingPathExtension().path
                )
            }
            .store(in: &objectBag)
    }
}

extension AppModel.AppearanceType: TextItem {
    static let allCases: [Self] = [.useSystemSettings, .lightMode, .darkMode]
    
    var title: String {
        switch self {
        case .useSystemSettings: return R.localizable.useSystemSetting()
        case .lightMode: return R.localizable.lightMode()
        case .darkMode: return R.localizable.darkMode()
        }
    }
}

final private class SettingView: Page {
    
    let appearancePicker = EnumPopupButton<AppModel.AppearanceType>()
    let debugSwitch = NSSwitch()
    let pathToUnityExeField = TextField()  => {
        $0.font = .monospacedSystemFont(ofSize: $0.font!.pointSize, weight: .regular)
    }
    let pathToUnityExeButton = Button(title: "Auto Fix")
    
    let pathToUnityHubField = TextField()  => {
        $0.font = .monospacedSystemFont(ofSize: $0.font!.pointSize, weight: .regular)
    }
    let pathToUnityHubButton = Button(title: "Auto Fix")
    
    let openSettingJoinButton = Button(title: "Open settings.json")
    
    override func onAwake() {        
        self.addSection(
            Area(icon: R.image.paramators(), title: "App Theme", message: "Select which app theme to display", control: appearancePicker)
        )
        self.addSection(
            Area(icon: R.image.paramators(), title: "Debug", message: "Toggle debug state", control: debugSwitch)
        )
        
        self.addSection(H4Title(text: "settings.json"))
        self.addSection(Section(title: "pathToUnityExe", items: [NSStackView() => {
            $0.addArrangedSubview(pathToUnityExeField)
            $0.addArrangedSubview(pathToUnityExeButton)
        }]))
        self.addSection(Section(title: "pathToUnityHub", items: [NSStackView() => {
            $0.addArrangedSubview(pathToUnityHubField)
            $0.addArrangedSubview(pathToUnityHubButton)
        }]))
        
        self.addSection(NSView() => {
            $0.snp.makeConstraints{ make in
                make.height.equalTo(16)
            }
        })
        self.addSection(openSettingJoinButton)
    }
}
