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
    public var dependency: [Dependency]
    private var component: [Dependency]
    private var builder: [Dependency]

    // Output
    public var name: String
    public var childBuilders: [Builder]
    public var childRIBs: [FunctionCallExpression]
    public var parentRIB: Builder?

    public var builtDependencies: [Dependency]

    public var nonCoreComponentName: String?

    var displayName: String {
        return name.replacingOccurrences(of: "Builder", with: "")
    }

    init(dict: [String: [Any]], names: BuilderParsedNames) {
        self.childRIBs = [FunctionCallExpression]()
        self.childBuilders = [Builder]()
        self.builtDependencies = [Dependency]()

        self.dependency = [Dependency]()
        self.component = [Dependency]()
        self.builder = [Dependency]()
        self.name = "" // TODO: FIX

        if let builderName = names.builderName {
            extractBuilder(name: builderName, dict: dict)
        }
        if let componentName = names.componentName {
            extractComponent(name: componentName, dict: dict, scope: .core)
        }
        if let dependencyName = names.dependencyName {
            extractDependency(name: dependencyName, dict: dict, scope: .core)
        }
        
        self.nonCoreComponentName = names.nonCoreComponentName

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

    // Given that non-core component depends on the Builder already being parsed in order that
    // the dependencies are meaningful, we have to add non-core component and dependencies
    // post-initial parse. This can be revised in future. TODO
    public func addNonCoreComponent(names: ComponentParsedNames, dict: [String: [Any]]) {

        if let dependencyName = names.dependencyName {
            extractDependency(name: dependencyName, dict: dict, scope: .nonCore)
        }
        if let componentName = names.componentName {
            extractComponent(name: componentName, dict: dict, scope: .nonCore)
        }
        extractSubRibs()
    }

    private func extractBuilder(name: String, dict: [String: [Any]]) {
        if let parsedBuilder = dict[name] as? [FunctionCallExpression] {
            self.name = name

            parsedBuilder.map { (expr) -> Dependency in
                return Dependency(builder: self, functionCall: expr)
            }.forEach { (dep) in
                builder.append(dep)
            }
        }
    }

    private func extractDependency(name: String, dict: [String: [Any]], scope: DependencyScope) {
        if let parsedDependency = dict[name] as? [ProtocolDeclaration.Member] {
            parsedDependency.map { (expr) -> Dependency in
                return Dependency(builder: self, protocolVariable: expr, scope: scope)
            }.forEach { (dep) in
                dependency.append(dep)
            }
        }
    }

    private func extractComponent(name: String, dict: [String: [Any]], scope: DependencyScope) {
        if let parsedComponent = dict[name] as? [FunctionCallExpression] {
            parsedComponent.map { (expr) -> Dependency in
                return Dependency(builder: self, functionCall: expr, scope: scope)
            }.forEach { (dep) in
                component.append(dep)
            }
        }
    }

    private func extractSubRibs() {

        var builtItems = [ Dependency ]()
        builtItems.append(contentsOf: component)
        builtItems.append(contentsOf: builder)

        for item in builtItems {
            if let function = item.functionCallExpression {

                if item.displayText.contains("Supplier") {
                    print("Supplier: \(item.displayText)")
                }

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
