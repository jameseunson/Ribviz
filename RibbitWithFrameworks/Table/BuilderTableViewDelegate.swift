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
    func didSelectItem(dep: Any)
}

class BuilderTableViewDelegate: NSObject, NSTableViewDelegate, BuilderTableRowViewListener {
    public var maxWidth: CGFloat = -1.0
    private let builder: Builder

    weak var listener: BuilderTableViewDelegateListener?

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
        guard let dep = tableView.dataSource?.tableView?(tableView, objectValueFor: nil, row: row) else {
            return nil
        }
        let row = BuilderTableRowView(dep: dep)
        row.listener = self
        maxWidth = CGFloat.maximum(maxWidth, row.intrinsicContentSize.width)
        return row
    }

    // MARK: - BuilderTableRowViewListener
    func didSelectItem(dep: Any) {
        listener?.didSelectItem(dep: dep)
    }
}
