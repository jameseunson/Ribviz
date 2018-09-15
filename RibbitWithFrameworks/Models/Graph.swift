//
//  Graph.swift
//  RibbitWithFrameworks
//
//  Created by James Eunson on 9/8/18.
//  Copyright © 2018 Uber. All rights reserved.
//

import AST

public final class GraphAnalysisResult {
    public var usedIn: [Builder]?
    public var builtIn: Builder?
    public var builtName: String?

    init(usedIn: [Builder]?, builtIn: Builder?, builtName: String?) {
        self.usedIn = usedIn
        self.builtIn = builtIn
        self.builtName = builtName
    }
}

public final class Graph {

    public let builders: [[Builder]]
    public var filterDependency: Dependency?

    private var flatBuilders: [Builder]

    var displayName: String {

        let name = flatBuilders.first?.name ?? "Graph"
        if let filter = filterDependency {
            return "Filtered graph of \(name)"
        }
        return name
    }

    init(builders: [[Builder]]) {
        self.builders = builders
        self.flatBuilders = [Builder]()

        for builderLevel in builders {
            for builder in builderLevel {
                flatBuilders.append(builder)
            }
        }
    }

    func analyze(dep: Dependency) -> GraphAnalysisResult {

        var usedIn = [Builder]()
        var builtIn: Builder?
        var builtName: String?

        for builder in flatBuilders {

            // Find builders that need this dep
            for reqDep in builder.dependency {

                if let reqDepProtocol = reqDep.protocolVariable,
                    let depProtocol = dep.protocolVariable,
                    case let AST.ProtocolDeclaration.Member.property(protocolDep) = depProtocol ,
                    case let AST.ProtocolDeclaration.Member.property(protocolReqDep) = reqDepProtocol,
                    protocolDep.textDescription == protocolReqDep.textDescription {

                    usedIn.append(builder)
                }
            }
        }

        for builder in flatBuilders {
            for builtDep in builder.builtDependencies {

                if let builtProtocol = builtDep.builtProtocol,
                    let requiredProtocol = dep.protocolVariable,
                    case let AST.ProtocolDeclaration.Member.property(requiredProtocolProperty) = requiredProtocol,
                    builtProtocol.textDescription == requiredProtocolProperty.typeAnnotation.type.textDescription {

                    builtName = builtDep.functionCallExpression?.postfixExpression.textDescription
                    builtIn = builder
                }
            }
        }

        return GraphAnalysisResult(usedIn: usedIn, builtIn: builtIn, builtName: builtName)
    }
}
