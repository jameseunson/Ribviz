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

class BuilderParser {

    func parse(fileURL: URL) throws -> Builder {
        let sourceFile = try SourceReader.read(at: fileURL.path.absolutePath)
        let parser = Parser(source: sourceFile)

        let topLevelDecl = try parser.parse()

        let lexicalParentAssignment = LexicalParentAssignment()
        lexicalParentAssignment.assign([topLevelDecl])

        let initializerVisitor = BuilderVisitor()
        try initializerVisitor.traverse(topLevelDecl)

        let names = BuilderParsedNames(builderNames: initializerVisitor.builderNames,
                                       componentNames: initializerVisitor.componentNames,
                                       dependencyNames: initializerVisitor.dependencyNames)

        return Builder(dict: initializerVisitor.targetExpressionLookup, names: names)
    }
}

final class BuilderParsedNames {
    let builderNames: [ String ]
    let componentNames: [ String ]
    let dependencyNames: [ String ]

    init(builderNames: [ String ], componentNames: [ String ], dependencyNames: [ String ]) {
        self.builderNames = builderNames
        self.componentNames = componentNames
        self.dependencyNames = dependencyNames
    }
}
