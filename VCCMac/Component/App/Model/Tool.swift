//
//  Tool.swift
//  VCCMac
//
//  Created by yuki on 2022/12/21.
//

import AppKit
import CoreUtil

final class Tool {
    let title: String
    let identifier: String
    let icon: NSImage
    
    private(set) var subtools = [Tool]()
    private(set) lazy var viewController = makeViewController()
    
    private let makeViewController: () -> NSViewController
    
    func subtool(_ subtool: Tool) -> Self {
        self.subtools.append(subtool)
        return self
    }
    
    init(title: String, identifier: String, icon: NSImage, viewController: @autoclosure @escaping () -> NSViewController) {
        self.title = title
        self.identifier = identifier
        self.icon = icon
        self.makeViewController = viewController
    }
}

extension Tool {
    static let project = Tool(
        title: R.localizable.project(), identifier: "project", icon: R.image.tool.project(),
        viewController: ProjectContainerViewController()
    )
    
    static let learn = Tool(
        title: R.localizable.learn(), identifier: "learn", icon: R.image.tool.learn(),
        viewController: LearnViewController()
    )
    static let settings = Tool(
        title: R.localizable.settings(), identifier: "settings", icon: R.image.tool.settings(),
        viewController: SettingViewController()
    )
    static let tools = Tool(
        title: R.localizable.tools(), identifier: "tools", icon: R.image.tool.tools(),
        viewController: NSViewController.__color(.green)
    )
    static let debug = Tool(
        title: R.localizable.debug(), identifier: "debug", icon: R.image.tool.tools(),
        viewController: __DebugViewController()
    )
    static let components = Tool(
        title: R.localizable.components(), identifier: "components", icon: R.image.tool.project(),
        viewController: __ComponentsViewController()
    )
}
