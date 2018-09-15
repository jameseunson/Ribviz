//
//  Dependency.swift
//  RibbitWithFrameworks
//
//  Created by James Eunson on 9/8/18.
//  Copyright © 2018 Uber. All rights reserved.
//

import AST

public enum DependencyType {
    case builtDependency
    case requiredDependency
}

public final class Dependency {

    public let builder: Builder
    public let dependency: Any // TODO: possibly removable

    public var usedIn: [Builder]?
    public var builtIn: Builder?

    public let type: DependencyType

    public var functionCallExpression: FunctionCallExpression?
    public var protocolVariable: ProtocolDeclaration.Member?

    public var builtProtocol: Type?

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

    init(builder: Builder, dependency: Any, usedIn: [Builder]? = nil, builtIn: Builder? = nil, type: DependencyType) {
        self.builder = builder
        self.dependency = dependency
        self.usedIn = usedIn
        self.builtIn = builtIn
        self.type = type
    }

    convenience init(builder: Builder, functionCall: FunctionCallExpression, usedIn: [Builder]? = nil, builtIn: Builder? = nil) {
        self.init(builder: builder, dependency: functionCall, usedIn: usedIn, builtIn: builder, type: .builtDependency)
        self.functionCallExpression = functionCall

        extractProtocolForBuiltDependency()
    }

    convenience init(builder: Builder, protocolVariable: ProtocolDeclaration.Member, usedIn: [Builder]? = nil, builtIn: Builder? = nil) {
        self.init(builder: builder, dependency: protocolVariable, usedIn: usedIn, builtIn: builder, type: .requiredDependency)
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
        if functionCallExpression.textDescription.contains("Builder(") ||
            functionCallExpression.textDescription.contains("Component(") ||
            functionCallExpression.textDescription.contains("ViewController(") ||
            functionCallExpression.textDescription.contains("Interactor(") {
            return
        }

        if self.functionCallExpression?.textDescription.contains("Booking") ?? false {
            print("Booking")
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
}
