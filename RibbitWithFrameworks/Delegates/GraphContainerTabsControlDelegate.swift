//
//  GraphContainerTabsControlDelegate.swift
//  RibbitWithFrameworks
//
//  Created by James Eunson on 11/24/18.
//  Copyright © 2018 Uber. All rights reserved.
//

import Foundation
import KPCTabsControl

class GraphContainerTabsControlDelegate: NSObject, TabsControlDelegate {

    private let graphControllerProvider: GraphControllerProviding

    init(graphControllerProvider: GraphControllerProviding) {
        self.graphControllerProvider = graphControllerProvider
    }

    func tabsControlDidChangeSelection(_ control: TabsControl, item: AnyObject) {

        let index = graphControllerProvider.graphControllers.index { (graphViewController: GraphViewController) -> Bool in
            guard let item = item as? GraphViewController else {
                return false
            }
            return graphViewController === item
        }
        guard let idx = index else {
            return
        }

        var i = 0
        for controller in graphControllerProvider.graphControllers {
            if i == idx {
                controller.view.isHidden = false
                graphControllerProvider.visibleGraphViewController = controller

            } else {
                controller.view.isHidden = true
            }

            i = i + 1
        }
    }
}
