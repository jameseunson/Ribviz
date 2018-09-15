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

        if let viewController = graphItem.viewController as? GraphContainerViewController {
            viewController.listener = self
        }
    }

    func didSelectItem(dep: Dependency) {
        if let viewController = detailItem.viewController as? DetailViewController {
            viewController.detailItem = dep
            viewController.listener = self
        }
    }

    func didUpdateSelection(selection: Any) {
        
    }
}

extension RootSplitViewController: DetailViewControllerListener {
    func didSelectDependencyGraphButton(dep: Dependency) {
        if let viewController = graphItem.viewController as? GraphContainerViewController {
            viewController.showFilteredGraph(dep: dep)
        }
    }
}
