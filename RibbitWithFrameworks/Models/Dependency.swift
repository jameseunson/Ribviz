//
//  Dependency.swift
//  RibbitWithFrameworks
//
//  Created by James Eunson on 9/8/18.
//  Copyright © 2018 Uber. All rights reserved.
//

import AST

public enum DependencyScope {
    case core
    case nonCore
}

public enum DependencyType {
    case builtDependency
    case requiredDependency
}

public final class Dependency: CustomDebugStringConvertible {

    public let builder: Builder
    public let dependency: Any // TODO: possibly removable

    public var usedIn: [Builder]?
    public var builtIn: Builder?

    public let type: DependencyType
    public let scope: DependencyScope

    public var functionCallExpression: FunctionCallExpression?
    public var protocolVariable: ProtocolDeclaration.Member?

    // Name of the protocol for this dependency (as opposed to the concrete name)
    // Eg BookingsServicing, as opposed to BookingsService
    public var builtProtocol: Type?
    public var builtName: String?

    private static let levelLimit = 10

    var displayText: String {

        switch type {
        case .builtDependency:
            return functionCallExpression?.postfixExpression.textDescription ?? "Unknown"

        case .requiredDependency:
            if let protocolVariable = protocolVariable,
                case let ProtocolDeclaration.Member.property(member) = protocolVariable {
                return member.typeAnnotation.type.textDescription
            }
            return "Unknown"
        }
    }

    init(builder: Builder, dependency: Any, usedIn: [Builder]? = nil, builtIn: Builder? = nil, type: DependencyType, scope: DependencyScope = .core) {
        self.builder = builder
        self.dependency = dependency
        self.usedIn = usedIn
        self.builtIn = builtIn
        self.type = type
        self.scope = scope
    }

    convenience init(builder: Builder, functionCall: FunctionCallExpression, usedIn: [Builder]? = nil, builtIn: Builder? = nil, scope: DependencyScope = .core) {
        self.init(builder: builder, dependency: functionCall, usedIn: usedIn, builtIn: builder, type: .builtDependency, scope: scope)
        self.functionCallExpression = functionCall

        extractProtocolForBuiltDependency()
    }

    convenience init(builder: Builder, protocolVariable: ProtocolDeclaration.Member, usedIn: [Builder]? = nil, builtIn: Builder? = nil, scope: DependencyScope = .core) {
        self.init(builder: builder, dependency: protocolVariable, usedIn: usedIn, builtIn: builder, type: .requiredDependency, scope: scope)
        self.protocolVariable = protocolVariable
    }

    // Find the related protocol for each built dependency
    // This is so we can associate protocol with implementation, eg: BookingService -> BookingServicing
    // This is important for finding where a required dependency is originally built
    func extractProtocolForBuiltDependency() {
        guard let functionCallExpression = functionCallExpression else {
            return
        }

        // Hack to filter out dependencies we're not interested in
        // TODO: Fix
        if functionCallExpression.textDescription.contains("Builder(") ||
            functionCallExpression.textDescription.contains("Component(") ||
            functionCallExpression.textDescription.contains("ViewController(") ||
            functionCallExpression.textDescription.contains("Interactor(") {
            return
        }

        if let variableContainer = traverseToEnclosingVariable(expr: functionCallExpression, level: 0) {
            if case let VariableDeclaration.Body.codeBlock(_, typeAnnotation, _) = variableContainer.body {

                builtProtocol = typeAnnotation.type
            }
        }
    }

    func traverseToEnclosingVariable(expr: ASTNode, level: Int = 0) -> VariableDeclaration? {
        if level == Dependency.levelLimit { // Ensure no infinite loop or excessive recursion
            return nil
        }
        guard let parent = expr.lexicalParent else {
            return nil
        }

        if parent is VariableDeclaration {
            return parent as? VariableDeclaration
        } else {
            return traverseToEnclosingVariable(expr: parent, level: level + 1)
        }
    }

    // MARK: - CustomDebugStringConvertible
    public var debugDescription: String {
        return "Dependency: \(displayText)"
    }
}
