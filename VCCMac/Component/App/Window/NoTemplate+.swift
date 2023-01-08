//
//  NoTemplate+.swift
//  VCCMac
//
//  Created by yuki on 2023/01/04.
//

import CoreUtil

final class NoTemplateViewController: NSViewController {
    let needReloadPublisher = PassthroughSubject<Void, Never>()
    
    private let cell = NoTemplateView()
    
    @Observable private var isAvailable = false
    
    
    override func loadView() { self.view = cell }
    
    override func chainObjectDidLoad() {
        guard let model = chainObject as? ProjectTempleteSelectModel else { return }
        
        Reachability.shared?.publisher
            .sink{[unowned self] in isAvailable = $0.connection != .unavailable }.store(in: &objectBag)
        
        self.$isAvailable
            .sink{[unowned self] in
                self.cell.installButton.isEnabled = $0
                self.cell.noConnectionLabel.isHidden = $0
            }
            .store(in: &objectBag)
        
        self.cell.installButton.actionPublisher
            .sink{[unowned self] in
                self.cell.installButton.isEnabled = false
                
                let toast = Toast(message: R.localizable.installingTempletes())
                toast.addSpinningIndicator()
        
                model.command.installTemplates().receive(on: .main)
                    .peek{
                        self.needReloadPublisher.send()
                        toast.close()
                    }
                    .catch{ error in
                        toast.close()
                        model.logger.error(error)
                    }
                    .finally {
                        self.cell.installButton.isEnabled = true
                    }
            }
            .store(in: &objectBag)
    }
}

final private class NoTemplateView: NSLoadStackView {
    let titleLabel = NSTextField(labelWithString: R.localizable.noTempletes()) => {
        $0.font = .systemFont(ofSize: 13)
        $0.textColor = .secondaryLabelColor
    }
    let installButton = Button(title: R.localizable.installTempletes())
    let noConnectionLabel = NSTextField(labelWithString: R.localizable.unableToConnectToTheInternet()) => {
        $0.font = .systemFont(ofSize: 12)
        $0.textColor = .systemRed
    }
    
    override func onAwake() {
        self.orientation = .vertical
        self.spacing = 12
        self.addArrangedSubview(titleLabel)
        self.addArrangedSubview(noConnectionLabel)
        self.addArrangedSubview(installButton)
    }
}
