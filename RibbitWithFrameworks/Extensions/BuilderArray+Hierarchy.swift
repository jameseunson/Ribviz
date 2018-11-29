//
//  BuilderArray+Hierarchy.swift
//  RibbitWithFrameworks
//
//  Created by James Eunson on 11/26/18.
//  Copyright © 2018 Uber. All rights reserved.
//

import Foundation

extension Array where Element : Builder {

    func createLevelOrderBuilders(filter: [Builder]? = nil) -> [[Builder]]? {

        var nodeCountLookup = [ String: Int ]()
        var nodeLookup = [ String: Builder ]()

        for node in self {
            nodeCountLookup[node.name] = node.totalNodesBeneath()
            nodeLookup[node.name] = node
        }

        let sorted = nodeCountLookup.sorted { $0.value > $1.value }
        if let rootName = sorted.first?.key,
            let builder = nodeLookup[rootName] {
            return builder.nodesAtEachDepth(filter: filter)
        }

        return nil
    }

    func createHierarchy() -> [Builder] {

        // ON^2, oh well
        for builder in self {
            for f in builder.childRIBs {

                // Check the corresponding childBuilder doesn't already exist
                let existingBuilders = builder.childBuilders.filter { (builder: Builder) -> Bool in
                    return builder.name == f.postfixExpression.textDescription
                }
                if existingBuilders.count > 0 {
                    continue
                }

                let matchingBuilders = self.filter { (builder: Builder) -> Bool in
                    return builder.name == f.postfixExpression.textDescription
                }

                if matchingBuilders.count == 1,
                    let matchingBuilder = matchingBuilders.first {
                    builder.childBuilders.append(matchingBuilder)
                    matchingBuilder.parentRIB = builder
                }
            }
        }

        return self
    }
}
