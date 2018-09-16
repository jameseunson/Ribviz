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

class BuilderParser {

    func parse(fileURL: URL) throws -> [Builder] {
        let sourceFile = try SourceReader.read(at: fileURL.path.absolutePath)
        let parser = Parser(source: sourceFile)

        guard let name = fileURL.lastPathComponent.components(separatedBy: ".").first else {
            throw BuilderParserError.parserError("Name doesn't follow expected format")
        }

        let topLevelDecl = try parser.parse()

        // Establish parent/child hierarchy
        let lexicalParentAssignment = LexicalParentAssignment()
        lexicalParentAssignment.assign([topLevelDecl])

        let initializerVisitor = BuilderVisitor()
        try initializerVisitor.traverse(topLevelDecl)

        var builders = [Builder]()
        for (dep, builder) in initializerVisitor.builderNames {

            let names = BuilderParsedNames(builderName: builder,
                                           componentName: initializerVisitor.componentNames[dep],
                                           dependencyName: dep)

            builders.append(Builder(dict: initializerVisitor.targetExpressionLookup, names: names))
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
