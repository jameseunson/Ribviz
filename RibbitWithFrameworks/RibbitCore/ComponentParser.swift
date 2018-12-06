//
//  ComponentParser.swift
//  RibbitWithFrameworks
//
//  Created by James Eunson on 11/24/18.
//  Copyright © 2018 Uber. All rights reserved.
//

import Foundation
import AST
import Parser
import Source
import Sema

enum ComponentParserError: Error {
    case parserError(String)
}

class ComponentParser: BaseParser {

    func parse(fileURL: URL, applyTo builders: [Builder]) throws {
        let topLevelDecl = try extractTopLevelDeclaration(fileURL: fileURL)
        let filename = try extractFilename(fileURL: fileURL)

        let componentVisitor = PresidioVisitor(filename: filename)
        try componentVisitor.traverse(topLevelDecl)

        // TODO: Probably need to rework this, this is somewhat messy
        if componentVisitor.componentNames.count > 0 {
            for (_, component) in componentVisitor.componentNames {

                guard let nonCoreDependencyName = componentVisitor.dependencyNames.last else {
                    print("Cannot find dependency name for non-core component: \(component)")
                    throw BuilderParserError.parserError("Cannot find dependency name for non-core component: \(component)")
                }

                let names = ComponentParsedNames(componentName: component,
                                               dependencyName: nonCoreDependencyName)
                let targetExpressionLookup = componentVisitor.targetExpressionLookup

                let builder = builders.filter {
                    return $0.nonCoreComponentName == component
                }.first

                guard let builderForNonCoreComponent = builder else {
                    print("Cannot find corresponding builder for non-core component: \(component)")
                    throw BuilderParserError.parserError("Cannot find corresponding builder for non-core component: \(component)")
                }

                builderForNonCoreComponent.addNonCoreComponent(names: names,
                                                               dict: targetExpressionLookup)
            }
        }
    }
}

public final class ComponentParsedNames {
    var componentName: String?
    var dependencyName: String?

    init(componentName: String?, dependencyName: String?) {
        self.componentName = componentName
        self.dependencyName = dependencyName
    }
}
