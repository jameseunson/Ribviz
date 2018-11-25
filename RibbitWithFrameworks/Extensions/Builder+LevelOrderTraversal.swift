//
//  Builder+LevelOrderTraversal
//  RibbitCore
//
//  Created by James Eunson on 9/4/18.
//

import Foundation

extension Builder {
    func totalNodesBeneath() -> Int {
        return totalNodesBeneath(node: self, depth: 0, visited: [self]).count
    }

    private func totalNodesBeneath(node: Builder, depth: Int, visited: [Builder]) -> [Builder] {
        var nodes = [Builder]()

        for node in node.childBuilders {
            nodes.append(node)

            // Ensure we're not following circular dependencies
            if !visited.contains(where: { (visitedBuilder: Builder) -> Bool in
                return visitedBuilder === node
            }) {
                var mutableVisited = visited
                mutableVisited.append(node)

                nodes.append(contentsOf: totalNodesBeneath(node: node, depth: depth + 1, visited: mutableVisited))
            }
        }

        return nodes
    }

    func nodesAtEachDepth() -> [[Builder]] {
        return nodesAtDepth(node: self, depth: 0, nodes: [[Builder]](), visited: [Builder]())
    }

    private func nodesAtDepth(node: Builder, depth: Int, nodes: [[Builder]], visited: [Builder]) -> [[Builder]] {

        var nodes = nodes
        if depth == nodes.count {
            nodes.append([node])

        } else {
            var nodeList = nodes[depth]
            nodeList.append(node)
            nodes[depth] = nodeList
        }

        var mutableVisited = visited
        mutableVisited.append(node)
        
        for node in node.childBuilders {

            // Ensure we're not following circular dependencies
            if !mutableVisited.contains(where: { (visitedBuilder: Builder) -> Bool in
                return visitedBuilder === node
            }) {
                nodes = nodesAtDepth(node: node, depth: depth + 1, nodes: nodes, visited: mutableVisited)
            }
        }
        return nodes
    }
}
