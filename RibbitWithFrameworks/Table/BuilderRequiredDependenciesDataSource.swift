//
//  BuilderRequiredDependenciesDataSource.swift
//  RibbitWithFrameworks
//
//  Created by James Eunson on 9/8/18.
//  Copyright © 2018 Uber. All rights reserved.
//

import Foundation
import Cocoa

class BuilderRequiredDependenciesDataSource: NSObject, NSTableViewDataSource {
    private let builder: Builder
    public var filteredDependency: Dependency?

    init(builder: Builder) {
        self.builder = builder
    }

    public func numberOfRows(in tableView: NSTableView) -> Int {
        if let filteredDependency = filteredDependency {
            return dependenciesFilteredBy(filteredDependency).count
        } else {
//            return min(builder.dependency.count, 10)
            return builder.dependency.count
        }
    }

    public func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if let filteredDependency = filteredDependency {
            return dependenciesFilteredBy(filteredDependency)[row]
        } else {
            return builder.dependency[row]
        }
    }

    func dependenciesFilteredBy(_ dependency: Dependency) -> [Dependency] {
        return builder.dependency.filter { (dep) -> Bool in
            if let built = dependency.builtProtocol {
                return built.textDescription == dep.displayText
            } else {
                return dependency.displayText == dep.displayText
            }
        }
    }
}
