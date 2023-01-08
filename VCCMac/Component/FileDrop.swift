//
//  FileDrop.swift
//  DevToys
//
//  Created by yuki on 2022/02/02.
//

import CoreUtil

final class FileDropSection: Section {
    
    var urlsPublisher: AnyPublisher<[URL], Never> {
        fileDrop.urlsPublisher.merge(with: openButton.urlPublisher.map{ [$0] }).eraseToAnyPublisher()
    }
    
    private let fileDrop = FileDrop()
    private let openButton = OpenSectionButton(title: "Open".localized(), image: R.image.open()!)
    
    override func onAwake() {
        super.onAwake()
        self.title = "File".localized()
        self.addToolbarItem(openButton)
        self.addStackItem(fileDrop)
        self.snp.makeConstraints{ make in
            make.height.equalTo(160)
        }
    }
}

extension NSPasteboard {
    func canReadTypes(_ types: [PasteboardType]) -> Bool {
        self.canReadItem(withDataConformingToTypes: types.map{ $0.rawValue })
    }
}

final class DropNotationView: NSLoadStackView {
    var title: String { get { titleLabel.stringValue } set { titleLabel.stringValue = newValue } }
    
    convenience init(title: String) {
        self.init()
        self.title = title
    }
    
    private let imageView = NSImageView(image: R.image.drop())
    private let titleLabel = NSTextField(labelWithString: "Drop Files Here") => {
        $0.textColor = .secondaryLabelColor
        $0.font = .systemFont(ofSize: 13, weight: .regular)
    }
    
    override func onAwake() {
        self.orientation = .vertical
        self.spacing = 12
        self.addArrangedSubview(imageView)
        self.addArrangedSubview(titleLabel)
    }
}

final class FileDrop: NSLoadView {
    
    let urlsPublisher = PassthroughSubject<[URL], Never>()
    
    private let backgroundLayer = ControlBackgroundLayer.animationDisabled()
    private let notationView = DropNotationView()
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        sender.draggingPasteboard.canReadTypes([.fileURL]) ? .copy : .none
    }
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let urls = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] else { return false }
        urlsPublisher.send(urls)
        return true
    }
    
    override func layout() {
        super.layout()
        self.backgroundLayer.frame = bounds
    }
    
    override func updateLayer() {
        backgroundLayer.update()
    }

    override func onAwake() {
        self.wantsLayer = true
        self.layer?.addSublayer(backgroundLayer)
        
        self.addSubview(notationView)
        self.notationView.snp.makeConstraints{ make in
            make.center.equalToSuperview()
        }
        
        self.registerForDraggedTypes([.fileURL])
    }
}
