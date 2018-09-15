//
//  Builder.swift
//  Ribbit
//
//  Created by James Eunson on 8/29/18.
//

import Foundation
import AST
import Parser
import Source

class Builder {

    // Input
    private var dependency: [ ProtocolDeclaration.Member ]
    private var component: [ FunctionCallExpression ]
    private var builder: [ FunctionCallExpression ]

    // Output
    public var childRIBs: [ FunctionCallExpression ]
    public var builtDependencies: [ FunctionCallExpression ]

    init(dict: [ String: [ Any ] ], names: BuilderParsedNames) {
        self.childRIBs = [ FunctionCallExpression ]()
        self.builtDependencies = [ FunctionCallExpression ]()

        self.dependency = [ ProtocolDeclaration.Member ]()
        self.component = [ FunctionCallExpression ]()
        self.builder = [ FunctionCallExpression ]()

        // TODO: Will eventually support multiple dependencies, builders
        // and components, for now just take first
        if let builderName = names.builderNames.first,
            let parsedBuilder = dict[builderName] as? [ FunctionCallExpression ] {
            self.builder.append(contentsOf: parsedBuilder)
        }
        if let componentName = names.componentNames.first,
            let parsedComponent = dict[componentName] as? [ FunctionCallExpression ] {
            self.component.append(contentsOf: parsedComponent)
        }
        if let dependencyName = names.dependencyNames.first,
            let parsedDependency = dict[dependencyName] as? [ ProtocolDeclaration.Member ] {
            self.dependency.append(contentsOf: parsedDependency)
        }

        extractSubRibs()
    }

    func extractSubRibs() {
        print("extractSubRibs")

        var builtItems = [ FunctionCallExpression ]()
        builtItems.append(contentsOf: component)
        builtItems.append(contentsOf: builder)

        for item in builtItems {
            if item.postfixExpression.description.contains("Builder") {
                childRIBs.append(item)
                print("child rib: \(item.postfixExpression)")

            } else {
                builtDependencies.append(item)
            }
        }
    }
}
