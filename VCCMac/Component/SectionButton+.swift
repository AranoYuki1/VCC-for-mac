//
//  SectionButton+.swift
//  DevToys
//
//  Created by yuki on 2022/01/30.
//

import CoreUtil

final class OpenSectionButton: SectionButton {
    
    let urlPublisher = PassthroughSubject<URL, Never>()
    
    var fileStringPublisher: AnyPublisher<String, Never> {
        urlPublisher.compactMap{ try? String(contentsOf: $0) }.eraseToAnyPublisher()
    }
    var fileDataPublisher: AnyPublisher<Data, Never> {
        urlPublisher.compactMap{ try? Data(contentsOf: $0) }.eraseToAnyPublisher()
    }
    
    @objc private func buttonAction(_: Any) {
        let panel = NSOpenPanel()
        guard panel.runModal() == .OK, let url = panel.url else { return }
        self.urlPublisher.send(url)
    }
    
    override func onAwake() {
        super.onAwake()
        self.toolTip = "Open".localized()
        self.title = ""
        self.image = R.image.open()
        self.setTarget(self, action: #selector(buttonAction))
    }
}
