//
//  RootWindowViewController.swift
//  RibbitWithFrameworks
//
//  Created by James Eunson on 9/8/18.
//  Copyright © 2018 Uber. All rights reserved.
//

import Foundation
import Cocoa

enum DisplayMode: String {
    case all = "Show all"
    case required = "Required dependencies only"
    case built = "Built dependencies only"
    case names = "Names only"

    static var allValues: [DisplayMode] {
        return [.all, .required, .built, .names]
    }
}

protocol RootWindowControllable: class {
    func closeProject()
}

class RootWindowController: NSWindowController, NSSearchFieldDelegate, RootWindowControllable, RootWindowDelegateListener {

    @IBOutlet weak var modeSelector: NSPopUpButton!
    @IBOutlet weak var searchField: NSSearchField!

    private let windowDelegate = RootWindowDelegate()

    var splitViewController: RootSplitViewControllable?

    override func windowDidLoad() {
        super.windowDidLoad()
        window?.delegate = windowDelegate
        windowDelegate.listener = self

        setupSearch()

        if let splitController = contentViewController as? RootSplitViewControllable {
            splitViewController = splitController
        }

        modeSelector.removeAllItems()
        for item in DisplayMode.allValues {
            modeSelector.addItem(withTitle: item.rawValue)
        }
    }

    @IBAction func didUpdateSelection(_ sender: NSPopUpButton) {

        let selectedMode = DisplayMode.allValues.filter { (mode: DisplayMode) -> Bool in
            guard let senderTitle = sender.selectedItem?.title else {
                return false
            }
            return senderTitle == mode.rawValue
        }
        if let mode = selectedMode.first {
            splitViewController?.updateDisplayMode(mode)
        }
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

    // MARK: - RootWindowDelegateListener
    func didAttemptClose() {
        splitViewController?.didAttemptClose()
    }

    var shouldAllowClose: Bool {
        return splitViewController?.shouldAllowClose ?? false
    }
}
