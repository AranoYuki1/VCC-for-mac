//
//  ToolmenuViewController.swift
//  DevToys
//
//  Created by yuki on 2022/01/29.
//

import CoreUtil

final class SidebarViewController: NSViewController {
    
    private let outlineView = NSOutlineView.list()
    private let scrollView = NSScrollView()
    
    @RestorableState("toolmenu.initial") private var isInitial = true
        
    @objc func onClick(_ outlineView: NSOutlineView) {
        self.onSelect(row: outlineView.clickedRow)
    }
    
    private func onSelect(row: Int) {
        guard let item = outlineView.item(atRow: row) as? SidebarItem, case let .tool(tool) = item else { return }        
        self.appModel.tool = tool
    } 
    
    override func loadView() {
        self.view = scrollView
        self.scrollView.documentView = outlineView
        self.scrollView.drawsBackground = false
        
        self.outlineView.setTarget(self, action: #selector(onClick))
        self.outlineView.outlineTableColumn = self.outlineView.tableColumns[0]
        self.outlineView.style = .sourceList
        self.outlineView.floatsGroupRows = false
    }
        
    override func chainObjectDidLoad() {
        // Datasource uses chainObject, call it in `chainObjectDidLoad`
        self.outlineView.delegate = self
        self.outlineView.dataSource = self
        self.outlineView.autosaveExpandedItems = true
        self.outlineView.autosaveName = "sidebar"
        if self.isInitial {
            self.isInitial = false
            self.outlineView.expandItem(nil, expandChildren: true)
        }
    }
}

extension SidebarViewController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let item = item as? SidebarItem, case let .tool(tool) = item else { return false }
        return !tool.subtools.isEmpty
    }
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        guard let item = item as? SidebarItem, case .tool = item else { return false }
        return true
    }
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil { return appModel.sidebarManager.sidebarItems()[index] }
        guard let item = item as? SidebarItem, case let .tool(tool) = item else { return false }
        return tool.subtools[index]
    }
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil { return appModel.sidebarManager.sidebarItems().count }
        guard let item = item as? SidebarItem, case let .tool(tool) = item else { return 0 }
        return tool.subtools.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        return SidebarCell.height
    }
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let item = item as? SidebarItem else { return nil }
        
        switch item {
        case let .tool(tool):
            let cell = SidebarCell()
            cell.title = tool.title
            cell.icon = tool.icon
            return cell
        case .separator:
            let box = NSBox()
            box.boxType = .separator
            return box
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, persistentObjectForItem item: Any?) -> Any? {
        guard let item = item as? SidebarItem, case let .tool(tool) = item else { return nil }
        return tool.identifier
    }
    func outlineView(_ outlineView: NSOutlineView, itemForPersistentObject object: Any) -> Any? {
        guard let identifier = object as? String else { return nil }
        if let tool = appModel.sidebarManager.toolForIdentifier(identifier) { return SidebarItem.tool(tool) }
        return nil
    }
}

extension SidebarViewController: NSOutlineViewDelegate {
    func outlineViewSelectionDidChange(_ notification: Notification) {
        self.onSelect(row: outlineView.selectedRow)
    }
}
