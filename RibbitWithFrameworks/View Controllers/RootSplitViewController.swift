//
//  RootSplitViewController.swift
//  RibbitWithFrameworks
//
//  Created by James Eunson on 9/8/18.
//  Copyright © 2018 Uber. All rights reserved.
//

import Foundation
import Cocoa

class RootSplitViewController: NSSplitViewController, GraphViewControllerListener {

    @IBOutlet weak var graphItem: NSSplitViewItem!
    @IBOutlet weak var detailItem: NSSplitViewItem!

    override func viewDidLoad() {
        super.viewDidLoad()

        if let viewController = graphItem.viewController as? GraphViewController {
            viewController.listener = self
        }
    }

    func didSelectItem(dep: Dependency) {
        if let viewController = detailItem.viewController as? DetailViewController {
            viewController.detailItem = dep
        }
    }

    func didUpdateSelection(selection: Any) {
        
    }
}
