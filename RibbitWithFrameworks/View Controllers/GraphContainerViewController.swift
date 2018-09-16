//
//  GraphContainerViewController.swift
//  RibbitWithFrameworks
//
//  Created by James Eunson on 9/15/18.
//  Copyright © 2018 Uber. All rights reserved.
//

import Cocoa
import SnapKit
import AST
import KPCTabsControl

protocol GraphContainerViewControllable: class {
    func filterVisibleGraphBy(query: String)
    func showFilteredGraph(dep: Dependency)
}

class GraphContainerViewController: NSViewController, GraphContainerViewControllable {
    
    @IBOutlet weak var tabsControl: TabsControl!
    @IBOutlet weak var contentView: NSView!

    private let parser: RibbitParser
    private var builders: [[Builder]]!

    private var graphs = [ Graph ]()
    private var graphControllers = [ GraphViewController ]()

    private var visibleGraphViewController: GraphViewController!

    weak var listener: GraphViewControllerListener?

    required init?(coder: NSCoder) {
        parser = RibbitParser()
        super.init(coder: coder)

        builders = parser.retrieveBuilders()
    }

    override func viewDidLoad() {
        tabsControl.dataSource = self
        tabsControl.delegate = self
        tabsControl.style = SafariStyle()

        addGraph()
    }

    private func addGraph(dep: Dependency? = nil) {

        if let controller = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil).instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "GraphViewController")) as? GraphViewController {

            controller.builders = builders
            controller.filterDependency = dep

            addChildViewController(controller)
            contentView.addSubview(controller.view)
            controller.view.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }

            controller.listener = self

            graphControllers.append(controller)
            graphs.append(controller.graph)

            tabsControl.reloadTabs()
            tabsControl.selectItemAtIndex(graphs.count - 1)
        }
    }

    // MARK: - GraphContainerViewControllable
    func filterVisibleGraphBy(query: String) {
        visibleGraphViewController.filterVisibleGraphBy(query: query)
    }

    func showFilteredGraph(dep: Dependency) {
        addGraph(dep: dep)
    }
}

extension GraphContainerViewController: TabsControlDelegate {
    func tabsControlDidChangeSelection(_ control: TabsControl, item: AnyObject) {

        let index = graphs.index { (graph: Graph) -> Bool in
            guard let item = item as? Graph else {
                return false
            }
            return graph === item
        }
        guard let idx = index else {
            return
        }

        var i = 0
        for controller in graphControllers {
            if i == idx {
                controller.view.isHidden = false
                visibleGraphViewController = controller

            } else {
                controller.view.isHidden = true
            }

            i = i + 1
        }
    }
}

extension GraphContainerViewController: TabsControlDataSource {
    func tabsControlNumberOfTabs(_ control: TabsControl) -> Int {
        return graphControllers.count
    }

    func tabsControl(_ control: TabsControl, titleForItem item: AnyObject) -> String {
        if let graph = item as? Graph {
            return graph.displayName
        }
        return "Unknown"
    }

    func tabsControl(_ control: TabsControl, itemAtIndex index: Int) -> Swift.AnyObject {
        return graphControllers[index].graph
    }

    func tabsControl(_ control: TabsControl, menuForItem item: AnyObject) -> NSMenu? {
        return nil
    }

    func tabsControl(_ control: TabsControl, iconForItem item: AnyObject) -> NSImage? {
        return nil
    }

    func tabsControl(_ control: TabsControl, titleAlternativeIconForItem item: AnyObject) -> NSImage? {
        return nil
    }
}

class TabObject {}

extension GraphContainerViewController: GraphViewControllerListener {
    func didSelectItem(dep: Dependency) {
        listener?.didSelectItem(dep: dep)
    }
}
