//
//  BuilderTableViewRow.swift
//  RibbitWithFrameworks
//
//  Created by James Eunson on 9/8/18.
//  Copyright © 2018 Uber. All rights reserved.
//

import Foundation
import Cocoa
import AST

protocol BuilderTableRowViewListener: class {
    func didSelectItem(dep: Dependency)
}

class BuilderTableRowView: NSTableRowView, InteractiveConstraintBasedTextViewListener {
    required init?(coder decoder: NSCoder) {
        fatalError("Not implemented")
    }

    private let dep: Dependency
    private let label: InteractiveConstraintBasedTextView

    weak var listener: BuilderTableRowViewListener?

    init(dep: Dependency) {
        label = InteractiveConstraintBasedTextView()
        self.dep = dep
        super.init(frame: .zero)

        label.applyDefault()
        label.listener = self
        label.font = NSFont.systemFont(ofSize: 12)

        addSubview(label)

        label.string = dep.displayText

        label.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
    }

    override var intrinsicContentSize: NSSize {
        return NSSize(width: label.intrinsicContentSize.width, height: -1)
    }

    // MARK: - InteractiveConstraintBasedTextViewListener
    func didTapTextView() {
        listener?.didSelectItem(dep: dep)
    }
}
