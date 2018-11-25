//
//  BuilderParser.swift
//  AST
//
//  Created by James Eunson on 8/21/18.
//

import Foundation
import AST
import Parser
import Source
import Sema

enum BuilderParserError: Error {
    case parserError(String)
}

class BuilderParser: BaseParser {

    func parse(fileURL: URL) throws -> [Builder] {

        let topLevelDecl = try extractTopLevelDeclaration(fileURL: fileURL)
        let filename = try extractFilename(fileURL: fileURL)

        let initializerVisitor = BuilderVisitor(filename: filename)
        try initializerVisitor.traverse(topLevelDecl)

        var builders = [Builder]()

        if initializerVisitor.pluginizedBuilderNames.count > 0 {
            for (component, builder) in initializerVisitor.pluginizedBuilderNames {

                let names = BuilderParsedNames(builderName: builder,
                                               componentName: component,
                                               dependencyName: initializerVisitor.dependencyNames.first)

                builders.append(Builder(dict: initializerVisitor.targetExpressionLookup, names: names))
            }

        } else {
            for (dep, builder) in initializerVisitor.builderNames {

                let names = BuilderParsedNames(builderName: builder,
                                               componentName: initializerVisitor.componentNames[dep],
                                               dependencyName: dep)

                builders.append(Builder(dict: initializerVisitor.targetExpressionLookup, names: names))
            }
        }
        return builders
    }
}

final class BuilderParsedNames {
    var builderName: String?
    var componentName: String?
    var dependencyName: String?

    init(builderName: String?, componentName: String?, dependencyName: String?) {
        self.builderName = builderName
        self.componentName = componentName
        self.dependencyName = dependencyName
    }
}
