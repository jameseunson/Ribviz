//
//  BaseParser.swift
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

enum ParserError: Error {
    case parserError(String)
}

class BaseParser {

    func extractTopLevelDeclaration(fileURL: URL) throws -> TopLevelDeclaration {

        let sourceFile = try SourceReader.read(at: fileURL.path.absolutePath)
        let parser = Parser(source: sourceFile)

        let topLevelDecl = try parser.parse()

        // Establish parent/child hierarchy
        let lexicalParentAssignment = LexicalParentAssignment()
        lexicalParentAssignment.assign([topLevelDecl])

        return topLevelDecl
    }

    func extractFilename(fileURL: URL) throws -> String {
        guard let name = fileURL.lastPathComponent.components(separatedBy: ".").first else {
            throw BuilderParserError.parserError("Name doesn't follow expected format")
        }
        return name
    }
}
