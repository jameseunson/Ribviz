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

class PresidioVisitor : ASTVisitor {
    var targetExpressions = [ FunctionCallExpression ]()
    var targetExpressionLookup = [ String: [ Any ] ]()

    var dependencyNames = [ String ]()

    var builderNames = [ String: String ]()
    var pluginizedBuilderNames = [ String: String ]()

    var componentNames = [ String: String ]()
    var nonCoreComponentNames = [ String: String ]()

    var pluginPointExpressions = [ String: [ConstantDeclaration] ]()

    let filename: String

    init(filename: String) {
        self.filename = filename
    }

    static let levelLimit = 10

    @discardableResult
    func visit(_ fce: FunctionCallExpression) throws -> Bool {

        // Skip 'shared' function call expresions and only extract their contents
        // eg. shared { Something() }, only get Something(), not shared { Something() }
        // Also misc junk filtering
        if fce.postfixExpression.description.contains("shared")
            || fce.postfixExpression.description.contains("super.init") {
            return true
        }

        targetExpressions.append(fce)

        guard let parentClass = traverseToEnclosingClass(expr: fce),
            let parentClassTypeName = parentClass.typeInheritanceClause?.primaryInheritanceClassName() else {
                return true
        }

        let name = parentClass.name.textDescription
        let parentClassGenericType = parentClass.typeInheritanceClause?.primaryGenericType()

        if !targetExpressionLookup.keys.contains(name) {
            targetExpressionLookup[name] = [ FunctionCallExpression ]()

            if let genericType = parentClassGenericType {
                if parentClassTypeName.contains("Component") {

                    if parentClassTypeName == "Component" || parentClassTypeName == "NonCoreComponent" {
                        componentNames[genericType.textDescription] = name

                        if parentClassTypeName == "Component" { // We don't need to find the non-core component of a non-core component, hence just component here!
                            if let _ = parentClass.typeInheritanceClause?.nonCoreGenericType() {
                                assertionFailure("NYI")
                            }
                        }

                    } else if parentClassTypeName == "PluginizableComponent" || parentClassTypeName == "PluginizedComponent" {

                        // AST doesn't like this syntax: NeedleFoundation.PluginizableComponent, so instead we use a regex
                        // TODO: Would be good to get SwiftAST fixed for this case
                        if let depRange = parentClass.textDescription.range(of: "<[a-zA-Z]+Dependency,", options: .regularExpression) {
                            let depName = parentClass.textDescription[depRange].components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: "")
                            componentNames[depName] = name
                        }

                        if let nonCoreGenericType = parentClass.typeInheritanceClause?.nonCoreGenericType() {
                            nonCoreComponentNames[name] = nonCoreGenericType.textDescription
                        }

                    } else {
                        print("PresidioVisitor: Unknown component type: \(parentClassTypeName)")
                    }

                } else if parentClassTypeName.contains("Builder") { // Includes PluginizedBuilder

                    if parentClassTypeName == "Builder" {
                        builderNames[genericType.textDescription] = name

                    } else if parentClassTypeName == "PluginizedBuilder" || parentClassTypeName == "NeedleBuilder" {
                        pluginizedBuilderNames[genericType.textDescription] = name

                    } else {
                        print("PresidioVisitor: Unknown builder type: \(parentClassTypeName)")
                    }

                } else if parentClassTypeName.contains("PluginPoint") {

                    if !pluginPointExpressions.keys.contains(name) {
                        pluginPointExpressions[name] = [ConstantDeclaration]()
                    }

                    for member in parentClass.members {
                        if case let ClassDeclaration.Member.declaration(declaration) = member {

                            // Extract dependencies for plugin point
                            if let const = declaration as? ConstantDeclaration {
                                pluginPointExpressions[name]?.append(const)

                            } else if let variable = declaration as? VariableDeclaration {

                                // Extract plugin factory type, so we can recognize it elsewhere
                                // if the plugin point does not define its own factories
                                if variable.textDescription.contains("pluginFactories"),
                                    case let VariableDeclaration.Body.codeBlock(_, typeAnnotation, _) = variable.body {

                                    let type = typeAnnotation.type
                                    print(typeAnnotation)
                                }
                            }
                        }
                    }
                }

            } else if parentClassTypeName.contains("Buildable") || parentClassTypeName.contains("Building") { // Custom builder with no generics, eg <ModeComponent, ModeListener, ModeRouter>
                if let inheritedType = parentClass.typeInheritanceClause?.primaryInheritanceClassName() {
                    builderNames[inheritedType] = name
                }

            } else {
                print("PresidioVisitor: Unhandled type: \(parentClassTypeName)")
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
        if level == PresidioVisitor.levelLimit { // Ensure no infinite loop or excessive recursion
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
