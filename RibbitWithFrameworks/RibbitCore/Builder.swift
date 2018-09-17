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

public class Builder: CustomDebugStringConvertible {

    // Input
    public var dependency: [ Dependency ]
    private var component: [ Dependency ]
    private var builder: [ Dependency ]

    // Output
    public var name: String
    public var childBuilders: [ Builder ]
    public var childRIBs: [ FunctionCallExpression ]
    public var parentRIB: Builder?

    public var builtDependencies: [ Dependency ]

    var displayName: String {
        return name.replacingOccurrences(of: "Builder", with: "")
    }

    init(dict: [ String: [ Any ] ], names: BuilderParsedNames) {
        self.childRIBs = [ FunctionCallExpression ]()
        self.childBuilders = [ Builder ]()
        self.builtDependencies = [ Dependency ]()

        self.dependency = [ Dependency ]()
        self.component = [ Dependency ]()
        self.builder = [ Dependency ]()
        self.name = "" // TODO: FIX

        if let builderName = names.builderName,
            let parsedBuilder = dict[builderName] as? [ FunctionCallExpression ] {
            self.name = builderName

            parsedBuilder.map { (expr) -> Dependency in
                return Dependency(builder: self, functionCall: expr)
            }.forEach { (dep) in
                builder.append(dep)
            }
        }

        if let componentName = names.componentName,
            let parsedComponent = dict[componentName] as? [ FunctionCallExpression ] {
            parsedComponent.map { (expr) -> Dependency in
                return Dependency(builder: self, functionCall: expr)
            }.forEach { (dep) in
                component.append(dep)
            }
        }
        if let dependencyName = names.dependencyName,
            let parsedDependency = dict[dependencyName] as? [ ProtocolDeclaration.Member ] {
            parsedDependency.map { (expr) -> Dependency in
                return Dependency.init(builder: self, protocolVariable: expr)
            }.forEach { (dep) in
                dependency.append(dep)
            }
        }

        extractSubRibs()
    }

    public func contains(_ filteredDependency: Dependency) -> Bool {

        if filteredDependency.functionCallExpression != nil {
            let foundBuiltDependency = builtDependencies.contains { (bd: Dependency) -> Bool in
                return bd.displayText == filteredDependency.displayText
            }
            let foundDependency = dependency.contains { (dep: Dependency) -> Bool in
                return dep.displayText == filteredDependency.builtProtocol?.textDescription ?? ""
            }
            return foundBuiltDependency || foundDependency

        } else {
            let foundBuiltDependency = builtDependencies.contains { (bd: Dependency) -> Bool in
                return bd.displayText == filteredDependency.displayText
            }
            let foundDependency = dependency.contains { (dep: Dependency) -> Bool in
                return dep.displayText == filteredDependency.displayText
            }
            return foundBuiltDependency || foundDependency
        }
    }

    private func extractSubRibs() {

        var builtItems = [ Dependency ]()
        builtItems.append(contentsOf: component)
        builtItems.append(contentsOf: builder)

        for item in builtItems {
            if let function = item.functionCallExpression {
                if function.postfixExpression.description.contains("Builder"),
                    !item.displayText.contains(name) {
                    childRIBs.append(function)
                } else {
                    builtDependencies.append(item)
                }
            }
        }
    }

    // MARK: - CustomDebugStringConvertible
    public var debugDescription: String {
        return name
    }
}
