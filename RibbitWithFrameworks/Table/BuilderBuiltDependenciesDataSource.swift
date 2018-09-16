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
    public var filteredDependency: Dependency?

    init(builder: Builder) {
        self.builder = builder
    }

    public func numberOfRows(in tableView: NSTableView) -> Int {
        if let filteredDependency = filteredDependency {
            return dependenciesFilteredBy(filteredDependency).count
        } else {
            return builder.builtDependencies.count
        }
    }

    public func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if let filteredDependency = filteredDependency {
            return dependenciesFilteredBy(filteredDependency)[row]
        } else {
            return builder.builtDependencies[row]
        }
    }

    func dependenciesFilteredBy(_ dependency: Dependency) -> [Dependency] {
        return builder.builtDependencies.filter { (builtDep) -> Bool in
            if let builtName = dependency.builtName {
                return builtName == builtDep.displayText
            } else {
                return dependency.displayText == builtDep.displayText
            }
        }
    }
}
