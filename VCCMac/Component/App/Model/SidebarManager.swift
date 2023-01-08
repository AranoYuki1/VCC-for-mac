//
//  SidebarManager.swift
//  DevToys
//
//  Created by yuki on 2022/02/12.
//

import CoreUtil
import OrderedCollections

enum SidebarItem {
    case tool(Tool)
    case separator
}

final class SidebarManager {
    public var showDebugItems = false
    
    private struct SidebarItemWrapper {
        let item: SidebarItem
        let onlyForDebug: Bool
    }
    
    private var toolIdentifierMap = [String: Tool]()
    private var items = [SidebarItemWrapper]()
    
    func registerTool(_ tool: Tool, onlyForDebug debug: Bool = false) {
        assert(toolIdentifierMap[tool.identifier] == nil, "Tool with identifier '\(tool.identifier)' has already been registered.")
        self.toolIdentifierMap[tool.identifier] = tool
        self.items.append(.init(item: .tool(tool), onlyForDebug: debug))
    }
    func registerSeparator(onlyForDebug debug: Bool = false) {
        self.items.append(.init(item: .separator, onlyForDebug: debug))
    }
    
    func sidebarItems() -> [SidebarItem] {
        return items.filter{ !$0.onlyForDebug || self.showDebugItems }.map{ $0.item }
    }
    func toolForIdentifier(_ identifier: String) -> Tool? {
        self.toolIdentifierMap[identifier]
    }
}

extension SidebarManager {
    static let shared = SidebarManager() => { manager in
        manager.registerTool(.project)
        manager.registerTool(.learn)
//        manager.registerTool(.tools)
        manager.registerSeparator()
        manager.registerTool(.settings)
        manager.registerTool(.debug, onlyForDebug: true)
        manager.registerTool(.components, onlyForDebug: true)
    }
}
