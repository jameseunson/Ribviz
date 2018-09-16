//
//  RootSplitViewController.swift
//  RibbitWithFrameworks
//
//  Created by James Eunson on 9/8/18.
//  Copyright © 2018 Uber. All rights reserved.
//

import Foundation
import Cocoa

protocol RootSplitViewControllable: class {
    func filterVisibleGraphBy(_ query: String)
}

class RootSplitViewController: NSSplitViewController, GraphViewControllerListener, RootSplitViewControllable {

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

    // RootSplitViewControllable
    func filterVisibleGraphBy(_ query: String) {
        if let viewController = graphItem.viewController as? GraphContainerViewController {
            viewController.filterVisibleGraphBy(query: query)
        }
    }
}

extension RootSplitViewController: DetailViewControllerListener {
    func didSelectDependencyGraphButton(dep: Dependency) {
        if let viewController = graphItem.viewController as? GraphContainerViewController {
            viewController.showFilteredGraph(dep: dep)
        }
    }
}
