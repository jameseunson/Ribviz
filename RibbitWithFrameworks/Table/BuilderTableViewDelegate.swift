//
//  BuilderTableViewDelegate.swift
//  RibbitWithFrameworks
//
//  Created by James Eunson on 9/8/18.
//  Copyright © 2018 Uber. All rights reserved.
//

import Foundation
import Cocoa

protocol BuilderTableViewDelegateListener: class {
    func didSelectItem(dep: Dependency)
}

class BuilderTableViewDelegate: NSObject, NSTableViewDelegate, BuilderTableRowViewListener {
    public var maxWidth: CGFloat = -1.0
    private let builder: Builder

    weak var listener: BuilderTableViewDelegateListener?

    var highlightQuery: String?

    init(builder: Builder) {
        self.builder = builder
    }

    func tableView(_ tableView: NSTableView, dataCellFor tableColumn: NSTableColumn?, row: Int) -> NSCell? {
        return nil
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        return nil
    }

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        guard let dep = tableView.dataSource?.tableView?(tableView, objectValueFor: nil, row: row) as? Dependency else {
            return nil
        }
        let row = BuilderTableRowView(dep: dep)
        row.listener = self
        row.highlightQuery = highlightQuery
        maxWidth = CGFloat.maximum(maxWidth, row.intrinsicContentSize.width)
        return row
    }

    // MARK: - BuilderTableRowViewListener
    func didSelectItem(dep: Dependency) {
        listener?.didSelectItem(dep: dep)
    }
}
