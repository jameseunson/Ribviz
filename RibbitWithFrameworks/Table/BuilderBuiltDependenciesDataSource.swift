//
//  BuilderTableDataSource.swift
//  RibbitWithFrameworks
//
//  Created by James Eunson on 9/8/18.
//  Copyright © 2018 Uber. All rights reserved.
//

import Foundation
import Cocoa

class BuilderBuiltDependenciesDataSource: NSObject, NSTableViewDataSource {
    private let builder: Builder

    init(builder: Builder) {
        self.builder = builder
    }

    public func numberOfRows(in tableView: NSTableView) -> Int {
        return builder.builtDependencies.count
    }

    public func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return builder.builtDependencies[row]
    }
}
