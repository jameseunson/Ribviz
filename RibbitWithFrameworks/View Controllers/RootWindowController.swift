//
//  RootWindowViewController.swift
//  RibbitWithFrameworks
//
//  Created by James Eunson on 9/8/18.
//  Copyright © 2018 Uber. All rights reserved.
//

import Foundation
import Cocoa

protocol RootWindowControllable: class {
    func closeProject()
}

class RootWindowController: NSWindowController, NSSearchFieldDelegate, RootWindowControllable {

    @IBOutlet weak var modeSelector: NSPopUpButton!
    @IBOutlet weak var searchField: NSSearchField!

    var splitViewController: RootSplitViewControllable?

    override func windowDidLoad() {
        super.windowDidLoad()

        setupSearch()

        if let splitController = contentViewController as? RootSplitViewControllable {
            splitViewController = splitController
        }
    }
    @IBAction func didUpdateSelection(_ sender: NSPopUpButton) {
        print("didUpdateSelection: \(sender.selectedItem)")

//        splitViewController?.didUpdateSelection(selection: <#T##Any#>)
    }

    func setupSearch() {

        let menu = NSMenu()
        menu.title = "Menu"

        let allMenuItem = NSMenuItem()
        allMenuItem.title = "All"

        let ribItem = NSMenuItem()
        ribItem.title = "RIBs"

        let depItem = NSMenuItem()
        depItem.title = "Dependencies"

        let componentItem = NSMenuItem()
        componentItem.title = "Components"

        menu.addItem(allMenuItem)
        menu.addItem(ribItem)
        menu.addItem(depItem)
        menu.addItem(componentItem)

        searchField.searchMenuTemplate = menu
        searchField.delegate = self
    }

    override func controlTextDidChange(_ obj: Notification) {
        guard let field = obj.object as? NSSearchField else {
            return
        }

        DispatchQueue.main.async {
            self.splitViewController?.filterVisibleGraphBy(field.stringValue)
        }
    }

    // MARK: - RootWindowControllable
    func closeProject() {
        splitViewController?.closeProject()
    }
}
