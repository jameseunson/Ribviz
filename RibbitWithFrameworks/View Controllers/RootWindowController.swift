//
//  RootWindowViewController.swift
//  RibbitWithFrameworks
//
//  Created by James Eunson on 9/8/18.
//  Copyright © 2018 Uber. All rights reserved.
//

import Foundation
import Cocoa

class RootWindowController: NSWindowController, NSSearchFieldDelegate {
    @IBOutlet weak var modeSelector: NSPopUpButton!
    @IBOutlet weak var searchField: NSSearchField!

    var splitViewController: RootSplitViewController?

    override func windowDidLoad() {
        super.windowDidLoad()

        setupSearch()

        if let splitController = contentViewController as? RootSplitViewController {
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
        splitViewController?.filterVisibleGraphBy(field.stringValue)
    }
}
