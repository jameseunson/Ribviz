//
//  PluginPointParser.swift
//  RibbitWithFrameworks
//
//  Created by James Eunson on 11/25/18.
//  Copyright © 2018 Uber. All rights reserved.
//

import Foundation
import AST
import Parser
import Source
import Sema

enum PluginPointParserParserError: Error {
    case parserError(String)
}

class PluginPointParser: BaseParser {

    func parse(fileURL: URL) throws {
        let topLevelDecl = try extractTopLevelDeclaration(fileURL: fileURL)
        let filename = try extractFilename(fileURL: fileURL)

        let pluginPointVisitor = PresidioVisitor(filename: filename)
        try pluginPointVisitor.traverse(topLevelDecl)

        if pluginPointVisitor.pluginPointExpressions.count > 0,
            let targetPluginPoint = pluginPointVisitor.pluginPointExpressions.keys.first,
            let expressions = pluginPointVisitor.targetExpressionLookup[targetPluginPoint] {

//            let names = PluginPointParsedNames(pluginPointName: targetPluginPoint, pluginFactoryNames: <#T##[String]?#>)
        }
    }
}

public final class PluginPointParsedNames {
    var pluginPointName: String?
    var pluginFactoryNames: [String]?
    var pluginFactoryType: String?

    init(pluginPointName: String?, pluginFactoryNames: [String]?, pluginFactoryType: String?) {
        self.pluginPointName = pluginPointName
        self.pluginFactoryNames = pluginFactoryNames
        self.pluginFactoryType = pluginFactoryType
    }
}
