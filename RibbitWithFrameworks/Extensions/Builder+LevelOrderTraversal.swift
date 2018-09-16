//
//  Builder+LevelOrderTraversal
//  RibbitCore
//
//  Created by James Eunson on 9/4/18.
//

import Foundation

extension Builder {
    func nodesAtEachDepth() -> [[Builder]] {
        return nodesAtDepth(node: self, depth: 0, nodes: [[Builder]]())
    }

    private func nodesAtDepth(node: Builder, depth: Int, nodes: [[Builder]]) -> [[Builder]] {

        var nodes = nodes
        if depth == nodes.count {
            nodes.append([node])

        } else {
            var nodeList = nodes[depth]
            nodeList.append(node)
            nodes[depth] = nodeList
        }

        for node in node.childBuilders {
            nodes = nodesAtDepth(node: node, depth: depth + 1, nodes: nodes)
        }
        return nodes
    }
}
