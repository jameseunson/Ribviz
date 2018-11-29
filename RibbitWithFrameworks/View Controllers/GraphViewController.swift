//
//  GraphViewController.swift
//  Ribbit
//
//  Created by James Eunson on 9/2/18.
//  Copyright © 2018 Uber. All rights reserved.
//

import Cocoa
import SnapKit
import AST
import KPCTabsControl

protocol GraphViewControllerListener: class {
    func didSelectItem(dep: Dependency)
}

protocol GraphViewControllable: class {
    func filterVisibleGraphBy(query: String)
}

class GraphViewController: NSViewController, GraphViewListener, GraphViewControllable {

    @IBOutlet weak var scrollView: NSScrollView!

    private var documentView: NSView!
    public var builders: [[Builder]] = [[Builder]]()

    public var graph: Graph!
    public var filterDependency: Dependency?

    public var graphView: GraphView!

    weak var listener: GraphViewControllerListener?

    override func viewDidLoad() {
        super.viewDidLoad()

        documentView = NSView(frame: CGRect(origin: .zero, size: CGSize(width: self.view.frame.size.width, height: self.view.frame.size.height)))
        documentView.wantsLayer = true

        scrollView.documentView = documentView

        if let dep = filterDependency,
            let root = dep.builtIn,
            let used = dep.usedIn {

            var flatBuilders = [Builder]()
            builders.forEach { (builderLevel: [Builder]) in
                flatBuilders.append(contentsOf: builderLevel)
            }
            var subgraphForDep = flatBuilders.filter { (builder: Builder) -> Bool in
                return used.contains(where: { (usedBuilder: Builder) -> Bool in
                    return usedBuilder === builder
                })
            }
            subgraphForDep.insert(root, at: 0)

            let hierarchicalBuilders = subgraphForDep.createHierarchy()
            let levelOrderBuilders = hierarchicalBuilders.createLevelOrderBuilders(filter: subgraphForDep)

            if let filteredBuilders = levelOrderBuilders {
                graph = Graph(builders: filteredBuilders)

            } else {
                graph = Graph(builders: builders)
            }

        } else {
            graph = Graph(builders: builders)
        }

        graph.filterDependency = filterDependency

        graphView = GraphView(graph: graph)
        graphView.listener = self
        documentView.addSubview(graphView)

        graphView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
    }

    override func viewDidLayout() {
        super.viewDidLayout()

        documentView.frame = CGRect(origin: .zero, size: CGSize(
            width: CGFloat.maximum(graphView.intrinsicContentSize.width, view.frame.size.width),
            height: CGFloat.maximum(graphView.intrinsicContentSize.height, view.frame.size.height)))
    }

    // MARK: - GraphViewControllable
    func filterVisibleGraphBy(query: String) {
        graphView.filterBy(query: query)
    }

    // MARK: - GraphViewListener
    func didSelectItem(dep: Dependency) {
        listener?.didSelectItem(dep: dep)
    }
}


