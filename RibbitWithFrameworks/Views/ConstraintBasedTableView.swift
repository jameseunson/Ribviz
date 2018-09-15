//
//  ConstraintBasedTableView.swift
//  RibbitWithFrameworks
//
//  Created by James Eunson on 9/8/18.
//  Copyright © 2018 Uber. All rights reserved.
//

import Foundation
import Cocoa

class ConstraintBasedTableView: NSTableView {

    override var intrinsicContentSize: NSSize {

        guard let dataSource = dataSource,
            let numberOfRows = dataSource.numberOfRows,
            let delegate = delegate as? BuilderTableViewDelegate else {
                return NSSize(width: -1.0, height: rowHeight)
        }

        let rows = numberOfRows(self)
        var rowTotalHeight: CGFloat = 0.0

        for i in 0..<rows {
            if let view = delegate.tableView(self, rowViewForRow: i) {
                rowTotalHeight += view.fittingSize.height
            }
        }

        let size = NSSize(width: delegate.maxWidth.rounded(.up), height: rowTotalHeight)
        return size
    }
}
