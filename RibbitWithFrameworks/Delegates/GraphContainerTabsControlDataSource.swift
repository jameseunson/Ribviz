//
//  GraphContainerTabsControlDataSource.swift
//  RibbitWithFrameworks
//
//  Created by James Eunson on 11/24/18.
//  Copyright © 2018 Uber. All rights reserved.
//

import Foundation
import KPCTabsControl
import Cocoa

protocol GraphContainerTabsControlDataSourceListener: class {
    func closeTab(index: Int)
}

class GraphContainerTabsControlDataSource: NSObject, TabsControlDataSource {

    weak var listener: GraphContainerTabsControlDataSourceListener?

    private let graphControllerProvider: GraphControllerProviding

    init(graphControllerProvider: GraphControllerProviding) {
        self.graphControllerProvider = graphControllerProvider
    }

    func tabsControlNumberOfTabs(_ control: TabsControl) -> Int {
        return graphControllerProvider.graphControllers.count
    }

    func tabsControl(_ control: TabsControl, titleForItem item: AnyObject) -> String {
        if let graphViewController = item as? GraphViewController,
            let graph = graphViewController.graph {
            return graph.displayName
        }
        return "Unknown"
    }

    func tabsControl(_ control: TabsControl, itemAtIndex index: Int) -> Swift.AnyObject {
        return graphControllerProvider.graphControllers[index]
    }

    func tabsControl(_ control: TabsControl, menuForItem item: AnyObject) -> NSMenu? {
        guard let graphController = item as? GraphViewController else {
            return nil
        }
        let index = graphControllerProvider.graphControllers.index { (g: GraphViewController) -> Bool in
            return g === graphController
        }
        guard let idx = index else {
            return nil
        }

        if idx == 0 {
            return nil
        }

        let menu = NSMenu.init()
        let menuItem = NSMenuItem.init(title: "Close Tab", action: #selector(closeTab(sender:)), keyEquivalent: "C")
        menuItem.target = self
        menuItem.isEnabled = true
        menuItem.tag = idx
        menuItem.tag = 1
        menu.addItem(menuItem)

        return menu
    }

    func tabsControl(_ control: TabsControl, iconForItem item: AnyObject) -> NSImage? {
        return nil
    }

    func tabsControl(_ control: TabsControl, titleAlternativeIconForItem item: AnyObject) -> NSImage? {
        return nil
    }

    // MARK: - Target Action
    @objc func closeTab(sender: NSMenuItem) {
        listener?.closeTab(index: sender.tag)
    }
}
