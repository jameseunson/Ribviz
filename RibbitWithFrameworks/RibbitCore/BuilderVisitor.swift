//
//  InitializerVisitor.swift
//  AST
//
//  Created by James Eunson on 8/21/18.
//

import Foundation
import AST
import Parser
import Source

class BuilderVisitor : ASTVisitor {
    var targetExpressions = [ FunctionCallExpression ]()
    var targetExpressionLookup = [ String: [ Any ] ]()

    var dependencyNames = [ String ]()
    var builderNames = [ String: String ]()
    var pluginizedBuilderNames = [ String: String ]()
    var componentNames = [ String: String ]()

    static let levelLimit = 10

    @discardableResult
    func visit(_ fce: FunctionCallExpression) throws -> Bool {

        // Skip 'shared' function call expresions and only extract their contents
        // eg. shared { Something() }, only get Something(), not shared { Something() }
        if fce.postfixExpression.description.contains("shared") {
            return true
        }

        targetExpressions.append(fce)

        if let parentClass = traverseToEnclosingClass(expr: fce),
            let parentClassTypeName = parentClass.typeInheritanceClause?.primaryInheritanceClassName() {
            
            let name = parentClass.name.textDescription
            let parentClassGenericType = parentClass.typeInheritanceClause?.primaryGenericType()

            if !targetExpressionLookup.keys.contains(name) {
                targetExpressionLookup[name] = [ FunctionCallExpression ]()

                if let genericType = parentClassGenericType {
                    if parentClassTypeName == "Component" {
                        componentNames[genericType.textDescription] = name

                    } else if parentClassTypeName.contains("Builder") { // Includes PluginizedBuilder

                        if parentClassTypeName == "Builder" {
                            builderNames[genericType.textDescription] = name

                        } else if parentClassTypeName == "PluginizedBuilder" {
                            pluginizedBuilderNames[genericType.textDescription] = name

                        } else {
                            print("BuilderVisitor: Unknown type: \(parentClassTypeName)")
                        }
                    }

                } else if parentClassTypeName.contains("NeedleFoundation") { // It's a PluginizableComponent, see comment below

                    // AST doesn't like this syntax: NeedleFoundation.PluginizableComponent, so instead we use a regex
                    // TODO: Would be good to get SwiftAST fixed for this case
                    if let depRange = parentClass.textDescription.range(of: "<[a-zA-Z]+Dependency,", options: .regularExpression) {
                        let depName = parentClass.textDescription[depRange].components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: "")
                        componentNames[depName] = name
                    }
                } else {
                    print("BuilderVisitor: Unhandled type: \(parentClassTypeName)")
                }
            }

            // Some pretty hacky filtering to get rid of non-class instantiations
            // This is because InitializerExpression doesn't seem to work in AST
            // so we have to try and guess which FunctionCallExpressions are actually initializers

            // Incidentally, good lord substrings in Swift 4 are complicated
            let firstCharString = String(fce.textDescription[fce.textDescription.startIndex])
            if firstCharString.uppercased() != firstCharString || !firstCharString.isAlphanumeric {
                // Ignore

            } else {
                targetExpressionLookup[name]?.append(fce)
            }
        }
        return true
    }

    @discardableResult
    func visit(_ pd: ProtocolDeclaration) throws -> Bool {

        if let typeInheritanceClause = pd.typeInheritanceClause,
            typeInheritanceClause.containsType("Dependency") {

            let name = pd.name.textDescription
            dependencyNames.append(name)

            for member in pd.members {
                if !targetExpressionLookup.keys.contains(name) {
                    targetExpressionLookup[name] = [ FunctionCallExpression ]()
                }
                targetExpressionLookup[name]?.append(member)
            }
        }

        return true
    }

    // MARK: - Helper
    private func traverseToEnclosingClass(expr: ASTNode, level: Int = 0) -> ClassDeclaration? {
        if level == BuilderVisitor.levelLimit { // Ensure no infinite loop or excessive recursion
            return nil
        }
        guard let parent = expr.lexicalParent else {
            return nil
        }

        if parent is ClassDeclaration {
            return parent as? ClassDeclaration
        } else {
            return traverseToEnclosingClass(expr: parent, level: level + 1)
        }
    }
}

extension String {
    var isAlphanumeric: Bool {
        return !isEmpty && range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil
    }
}
