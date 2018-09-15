//
//  Dependency.swift
//  RibbitWithFrameworks
//
//  Created by James Eunson on 9/8/18.
//  Copyright © 2018 Uber. All rights reserved.
//

final class Dependency {
    public let builder: Builder
    public let dependency: Any

    public var usedIn: [Builder]?
    public var builtIn: Builder?

    init(builder: Builder, dependency: Any, usedIn: [Builder]? = nil, builtIn: Builder? = nil) {
        self.builder = builder
        self.dependency = dependency
        self.usedIn = usedIn
        self.builtIn = builtIn
    }
}
