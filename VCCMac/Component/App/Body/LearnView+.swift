//
//  LearnView+.swift
//  VCCMac
//
//  Created by yuki on 2023/01/08.
//

import CoreUtil

final class LearnViewController: NSViewController {
    private let cell = LearnView()
    
    override func loadView() { self.view = cell }
    
    override func chainObjectDidLoad() {
        
    }
}

private final class LearnView: Page {
    override func onAwake() {
        self.addSection(H2Title(text: "Udon"))
        self.addSection(Paragraph(text: "Learn how to get set up to create Udon-powered Worlds in VRChat."))
        self.addSection(Button(title: "Learn More") => {
            $0.actionPublisher
                .sink{ NSWorkspace.shared.open(URL(string: "https://docs.vrchat.com/docs/getting-started-with-udon")!) }
                .store(in: &objectBag)
        }, alignment: .left)
        
        self.addSection(SeparatorView())
        
        
        self.addSection(H2Title(text: "Avatars 3.0"))
        self.addSection(Paragraph(text: """
Avatars 3.0 is our name for all the features available for avatars in VRChat. AV3's features are focused on improving expression, performance, and the abilities of avatars in VRChat.

Avatars 3.0 is heavily integrated with the Action Menu for controlling and interacting with the avatar you're wearing. It's probably best if you hop in and try out the Action Menu before building an AV3 avatar!
"""))
        self.addSection(Button(title: "Learn More") => {
            $0.actionPublisher
                .sink{ NSWorkspace.shared.open(URL(string: "https://docs.vrchat.com/docs/avatars-30")!) }
                .store(in: &objectBag)
        }, alignment: .left)
        
        self.addSection(SeparatorView())
        
        
        self.addSection(H2Title(text: "Forums"))
        self.addSection(Paragraph(text: """
Our forums are a place to search for info, ask questions, and find out about cool things other people are making
"""))
        self.addSection(Button(title: "Learn More") => {
            $0.actionPublisher
                .sink{ NSWorkspace.shared.open(URL(string: "https://ask.vrchat.com/")!) }
                .store(in: &objectBag)
        }, alignment: .left)
        
        
    }
}
