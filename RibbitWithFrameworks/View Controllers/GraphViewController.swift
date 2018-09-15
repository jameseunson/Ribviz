//
//  ViewController.swift
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

class GraphViewController: NSViewController, GraphViewListener {

    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var tabsControl: TabsControl!

    private var documentView: NSView!
    public var builders: [[Builder]]!

    public var graph: Graph!
    public var filterDependency: Dependency?

    private var graphView: GraphView!

    weak var listener: GraphViewControllerListener?

    override func viewDidLoad() {
        super.viewDidLoad()

        documentView = NSView(frame: CGRect(origin: .zero, size: CGSize(width: self.view.frame.size.width, height: self.view.frame.size.height)))
        documentView.wantsLayer = true

        scrollView.documentView = documentView

        graph = Graph(builders: builders)
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

    // MARK: - GraphViewListener
    func didSelectItem(dep: Dependency) {
        listener?.didSelectItem(dep: dep)
    }
}


