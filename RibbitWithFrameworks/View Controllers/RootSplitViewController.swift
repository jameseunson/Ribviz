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
    func closeProject()
}

class RootSplitViewController: NSSplitViewController, GraphViewControllerListener, RootSplitViewControllable {

    @IBOutlet weak var graphItem: NSSplitViewItem!
    @IBOutlet weak var detailItem: NSSplitViewItem!

    var graphContainerController: GraphContainerViewControllable?

    override func viewDidLoad() {
        super.viewDidLoad()

        if let viewController = graphItem.viewController as? GraphContainerViewController {
            viewController.listener = self
            graphContainerController = viewController
        }
    }

    func didSelectItem(dep: Dependency) {
        if let viewController = detailItem.viewController as? DetailViewController {
            viewController.detailItem = dep
            viewController.listener = self
        }
    }

    func didUpdateSelection(selection: Any) {
        // TODO:
    }

    // MARK: - RootSplitViewControllable
    func filterVisibleGraphBy(_ query: String) {
        graphContainerController?.filterVisibleGraphBy(query: query)
    }

    func closeProject() {
        graphContainerController?.closeProject()
    }
}

extension RootSplitViewController: DetailViewControllerListener {
    func didSelectDependencyGraphButton(dep: Dependency) {
        if let viewController = graphItem.viewController as? GraphContainerViewController {
            viewController.showFilteredGraph(dep: dep)
        }
    }
}
