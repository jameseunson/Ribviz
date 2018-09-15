//
//  GraphView.swift
//  RibbitWithFrameworks
//
//  Created by James Eunson on 9/8/18.
//  Copyright © 2018 Uber. All rights reserved.
//

import Foundation
import Cocoa
import AST

protocol GraphViewListener: class {
    func didSelectItem(dep: Dependency)
}

class GraphView: NSView, BuilderViewListener {

    private let graph: Graph

    private let builders: [[Builder]]
    private var levelStackViews: [NSStackView]!
    private var builderViewLookup: [String: BuilderView]

    weak var listener: GraphViewListener?

    required init?(coder decoder: NSCoder) {
        fatalError("Not implemented")
    }

    init(builders: [[Builder]]) {
        levelStackViews = [NSStackView]()
        self.graph = Graph(builders: builders)
        self.builders = builders
        self.builderViewLookup = [String: BuilderView]()
        super.init(frame: .zero)

        var i = 0
        for builderLevel in builders {

            let stackView = NSStackView()
            stackView.distribution = .equalCentering
            stackView.alignment = .top

            stackView.spacing = 20
            levelStackViews.append(stackView)

            addSubview(stackView)

            for builder in builderLevel {

                let builderView = BuilderView(builder: builder)
                builderView.listener = self
                builderViewLookup[builder.name] = builderView

                stackView.addArrangedSubview(builderView)

                if i == 0 {
                    stackView.snp.makeConstraints { (maker) in
                        maker.top.equalToSuperview().offset(20)
                        maker.centerX.equalToSuperview()
                    }
                } else {
                    let lastStackView = levelStackViews[i - 1]

                    stackView.snp.makeConstraints { (maker) in
                        maker.centerX.equalToSuperview()
                        maker.top.equalTo(lastStackView.snp.bottom).offset(40)
                    }
                }
            }

            i = i + 1
        }
    }

    override var intrinsicContentSize: NSSize {

        return levelStackViews.map { (stackView: NSStackView) -> CGRect in
            return stackView.frame

        }.reduce(.zero) { (result, curr) -> CGRect in
            return result.union(curr)

        }
        .size
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // TODO: Cleanup
        // Draw lines between each level
        var i = 0
        for stackView in levelStackViews {
            if stackView == levelStackViews.first {
                i = i + 1
                continue
            }

            let lastLevelStackView = levelStackViews[i - 1]
            var parentBuilders = [Builder]()

            // Extract builders from the views from the previous level
            for builderView in lastLevelStackView.arrangedSubviews {
                if let builderView = builderView as? BuilderView {
                    parentBuilders.append(builderView.builder)
                }
            }

            // For views for this level, for each one extract the builder
            // and try to find it in the childBuilders array of each parent builder
            // If we have a match, the child is a descendant of the parent on the previous
            // level and a line is drawn between them
            for builderView in stackView.arrangedSubviews {
                if let builder = (builderView as? BuilderView)?.builder {
                    let parent = parentBuilders.filter { (parent: Builder) -> Bool in
                        parent.childBuilders.contains(where: { (child: Builder) -> Bool in return child === builder })
                    }.first

                    if let parent = parent,
                        let parentIndex = parentBuilders.index(where: { $0 === parent }) {

                        let parentView = lastLevelStackView.arrangedSubviews[parentIndex]

                        let path = NSBezierPath()

                        // We have to translate the frame of the builder view from the
                        // NSStackView context to the GraphView context
                        let graphParentFrame = lastLevelStackView.convert(parentView.frame, to: self)
                        let graphBuilderFrame = stackView.convert(builderView.frame, to: self)

                        path.move(to: NSPoint(x: graphBuilderFrame.midX, y: graphBuilderFrame.maxY))
                        path.line(to: NSPoint(x: graphParentFrame.midX, y: graphParentFrame.minY))
                        NSColor(white: 0, alpha: 0.15).set()
                        path.lineWidth = 1
                        path.stroke()
                    }
                }
            }

            i = i + 1
        }
    }

    // MARK: - BuilderViewListener
    func didSelectItem(dep: Dependency) {

        let result = graph.analyze(dep: dep)
        dep.usedIn = result.usedIn
        dep.builtIn = result.builtIn

        if let usedIn = result.usedIn {
            for usedBuilder in usedIn {
                if let builderView = builderViewLookup[usedBuilder.name] {
                    builderView.layer?.backgroundColor = NSColor.red.cgColor

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        builderView.layer?.backgroundColor = NSColor.clear.cgColor
                    }
                }
            }
        }

        if let builtIn = result.builtIn {
            if let builderView = builderViewLookup[builtIn.name] {
                builderView.layer?.backgroundColor = NSColor.blue.cgColor

                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    builderView.layer?.backgroundColor = NSColor.clear.cgColor
                }
            }
        }

        listener?.didSelectItem(dep: dep)
    }
}

