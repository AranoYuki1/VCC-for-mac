//
//  RequirementFailureReason.swift
//  VCCMac
//
//  Created by yuki on 2023/01/04.
//

import CoreUtil

struct RequirementFailureReason {
    let title: String
    let message: String
    let setupHandler: (RequirementCell) -> ()
    var isRecoverable: Bool = true
    
    static func make(model: AppFailureModel, from checkerReason: VPMRequirementChecker.FailureReason) -> RequirementFailureReason {
        func imake() -> RequirementFailureReason {
            switch checkerReason.failureType {
            case .vpmNotFound: return makeVPMNotFound(model: model)
            case .vpmNotValid(let message): return makeVPMNotValid(message: message, model: model)
            case .unityHubNotFound: return makeUnityHubNotFound(model: model)
            case .unityNotFound: return makeUnityNotFound(model: model)
            case .dotnetVersionIsNotValid(let requiedVersion, let message): return makeDotnetVersionIsNotValid(requiedVersion, message, model: model)
            case .dotnetNotFound: return makeDotnetNotInstalled(model: model)
            case .unknown(let string): return makeUnknown(string)
            }
        }
        
        var reason = imake()
        reason.isRecoverable = checkerReason.recoverable
        
        print(checkerReason)
        return reason
    }
    
    private static func makeDotnetNotInstalled(model: AppFailureModel) -> RequirementFailureReason {
        RequirementFailureReason(
            title: R.localizable.dotnetIsNotInstalled(),
            message: R.localizable.dotnetIsNotInstalledMessage(),
            setupHandler: { cell in
                let openTermianlButton = Button(title: R.localizable.downloadDotnet()) => {
                    $0.actionPublisher
                        .sink{
                            NSWorkspace.shared.open(URL(string: "https://dotnet.microsoft.com/download/dotnet/thank-you/sdk-6.0.404-macos-x64-installer")!)
                        }
                        .store(in: &cell.objectBag)
                }
                
                cell.addArrangedSubview(NSStackView() => {
                    $0.addArrangedSubview(openTermianlButton)
                })
            }
        )
    }
    
    private static func makeDotnetVersionIsNotValid(_ requiedVersion: String, _ message: String, model: AppFailureModel) -> RequirementFailureReason {
        RequirementFailureReason(
            title: R.localizable.dotnetIsNotValid(),
            message: R.localizable.dotnetIsNotValidMessage(),
            setupHandler: { cell in
                let openTermianlButton = Button(title: R.localizable.downloadDotnet()) => {
                    $0.actionPublisher
                        .sink{
                            NSWorkspace.shared.open(URL(string: "https://dotnet.microsoft.com/download/dotnet/thank-you/sdk-6.0.404-macos-x64-installer")!)
                        }
                        .store(in: &cell.objectBag)
                }
                
                cell.addArrangedSubview(NSStackView() => {
                    $0.addArrangedSubview(openTermianlButton)
                })
            }
        )
    }
    
    private static func makeUnknown(_ message: String) -> RequirementFailureReason {
        RequirementFailureReason(
            title: R.localizable.unkownError(),
            message: R.localizable.unkownErrorMessage(),
            setupHandler: { cell in
                let codeView = CodeView()
                cell.addArrangedSubview(codeView)
                codeView.string = message
                codeView.snp.makeConstraints{ make in
                    make.left.right.equalToSuperview().inset(16)
                }
            }
        )
    }
    
    private static func makeUnityHubNotFound(model: AppFailureModel) -> RequirementFailureReason {
        RequirementFailureReason(
            title: R.localizable.unityHubNotFound(),
            message: R.localizable.unityHubNotFoundMessage(),
            setupHandler: { cell in
                let autoFixButton = Button(title: R.localizable.autoFix()) => {
                    $0.actionPublisher
                        .sink{ do { try model.appModel.commandSetting.autoFixPathToUnityHub() } catch { Toast(error: error).show() } }
                        .store(in: &cell.objectBag)
                }
                let openHubButton = Button(title: R.localizable.downloadUnityHub()) => {
                    $0.actionPublisher
                        .sink{ NSWorkspace.shared.open(URL(string: "https://unity.com/download")!) }
                        .store(in: &cell.objectBag)
                }
                
                cell.addArrangedSubview(NSStackView() => {
                    $0.addArrangedSubview(autoFixButton)
                    $0.addArrangedSubview(openHubButton)
                })
            }
        )
    }
    
    private static func makeUnityNotFound(model: AppFailureModel) -> RequirementFailureReason {
        RequirementFailureReason(
            title: R.localizable.unityNotFound(),
            message: R.localizable.unityHubNotFoundMessage(),
            setupHandler: { cell in
                let autoFixButton = Button(title: R.localizable.autoFix()) => {
                    $0.actionPublisher
                        .sink{ do { try model.appModel.commandSetting.autoFixPathToUnityExe() } catch { Toast(error: error).show() } }
                        .store(in: &cell.objectBag)
                }
                let openHubButton = Button(title: R.localizable.openUnityHub()) => {
                    $0.actionPublisher
                        .sink{ NSWorkspace.shared.openApplication(at: URL(filePath: "/Applications/Unity Hub.app/"), configuration: .init()) }
                        .store(in: &cell.objectBag)
                }
                
                cell.addArrangedSubview(NSStackView() => {
                    $0.addArrangedSubview(autoFixButton)
                    $0.addArrangedSubview(openHubButton)
                })
            }
        )
    }
    
    private static func makeVPMNotValid(message: String, model: AppFailureModel) -> RequirementFailureReason {
        RequirementFailureReason(
            title: R.localizable.vccIsNotValid(),
            message: R.localizable.vccIsNotValidMessage(),
            setupHandler: { cell in
                let codeView = CodeView()
                cell.addArrangedSubview(codeView)
                codeView.string = message
                codeView.snp.makeConstraints{ make in
                    make.left.right.equalToSuperview().inset(16)
                }
            }
        )
    }
    
    private static func makeVPMNotFound(model: AppFailureModel) -> RequirementFailureReason {
        RequirementFailureReason(
            title: R.localizable.vccIsNotInstalled(),
            message: R.localizable.vccIsNotInstalledMessage(),
            setupHandler: { cell in
                let codeView = CodeView()
                codeView.string = "dotnet tool install --global vrchat.vpm.cli"
                cell.addArrangedSubview(codeView)
                codeView.snp.makeConstraints{ make in
                    make.left.right.equalToSuperview().inset(16)
                }

                let fixButton = Button(title: R.localizable.autoFix())
                fixButton.actionPublisher
                    .sink{
                        fixButton.isEnabled = false
                        let catalyst = ShellCatalyst(logger: model.logger)
                        let command = VPMInstallCommand(catalyst: catalyst)
                        let toast = Toast(message: R.localizable.installingVPMCommand())
                        toast.addSpinningIndicator()
                        toast.show(.whileDeinit)
                        
                        command.installedVPM()
                            .receive(on: .main)
                            .finally { toast.close() }
                            .peek{_ in Toast(message: R.localizable.vpmCommandInstalled()).show() }
                            .catch{ Toast(error: $0).show() }
                            .finally { model.appModel.reloadPublisher.send() }
                    }
                    .store(in: &cell.objectBag)
                
                cell.addArrangedSubview(NSStackView() => {
                    $0.addArrangedSubview(fixButton)
                })
            })
    }
}
