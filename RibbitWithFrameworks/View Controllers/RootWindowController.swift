//
//  RootWindowViewController.swift
//  RibbitWithFrameworks
//
//  Created by James Eunson on 9/8/18.
//  Copyright © 2018 Uber. All rights reserved.
//

import Foundation
import Cocoa

class RootWindowController: NSWindowController {
    @IBOutlet weak var modeSelector: NSPopUpButton!
    @IBOutlet weak var searchField: NSSearchField!

    var splitViewController: RootSplitViewController?

    override func windowDidLoad() {
        super.windowDidLoad()

        if let splitController = contentViewController as? RootSplitViewController {
            splitViewController = splitController
        }
    }
    @IBAction func didUpdateSelection(_ sender: NSPopUpButton) {
        print("didUpdateSelection: \(sender.selectedItem)")

//        splitViewController?.didUpdateSelection(selection: <#T##Any#>)
    }
}
