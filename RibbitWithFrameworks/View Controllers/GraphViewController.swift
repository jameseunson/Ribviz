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

protocol GraphViewControllerListener: class {
    func didSelectItem(dep: Dependency)
}

class GraphViewController: NSViewController, GraphViewListener {

    @IBOutlet weak var scrollView: NSScrollView!

    private var documentView: NSView!
    private var builders: [[Builder]]!
    private var graphView: GraphView!

    private let parser: RibbitParser

    weak var listener: GraphViewControllerListener?

    required init?(coder: NSCoder) {
        parser = RibbitParser()
        super.init(coder: coder)

        builders = parser.retrieveBuilders()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        documentView = NSView(frame: CGRect(origin: .zero, size: CGSize(width: self.view.frame.size.width, height: self.view.frame.size.height)))
        documentView.wantsLayer = true

        scrollView.documentView = documentView

        graphView = GraphView(builders: builders)
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




