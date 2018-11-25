//
//  TypeInheritanceClause+Extensions.swift
//  AST
//
//  Created by James Eunson on 8/21/18.
//

import Foundation
import AST
import Parser
import Source

extension TypeInheritanceClause {
    func containsType(_ typeString: String) -> Bool {
        return self.typeInheritanceList.filter({ (type: TypeIdentifier) -> Bool in
            type.textDescription.contains(typeString)
        }).count > 0
    }

    func isType(_ typeString: String) -> Bool {
        return self.typeInheritanceList.filter({ (type: TypeIdentifier) -> Bool in
            type.textDescription == typeString
        }).count > 0
    }

    func primaryInheritanceClassName() -> String? {
        if let primaryClass = self.typeInheritanceList.first {
            let parentClassTypeNames = primaryClass.names

            if let parentClassTypeNameFirst = parentClassTypeNames.first {
                if parentClassTypeNameFirst.name.textDescription == "NeedleFoundation"
                    || parentClassTypeNameFirst.name.textDescription == "Presidio",
                    parentClassTypeNames.count > 1 {
                    return parentClassTypeNames[1].name.textDescription // Return the type name *after* the initial namespace scope

                } else {
                    return parentClassTypeNameFirst.name.textDescription
                }
            }
        }
        return nil
    }

    func primaryGenericType() -> Type? {
        if let primaryClass = self.typeInheritanceList.first {
            let parentClassTypeNames = primaryClass.names

            if let parentClassTypeNameFirst = parentClassTypeNames.first {
                if parentClassTypeNameFirst.name.textDescription == "NeedleFoundation"
                    || parentClassTypeNameFirst.name.textDescription == "Presidio",
                    parentClassTypeNames.count > 1 {
                    return parentClassTypeNames[1].genericArgumentClause?.argumentList.first // Return the type name *after* the initial namespace scope

                } else {
                    return parentClassTypeNameFirst.genericArgumentClause?.argumentList.first
                }
            }
        }
        return nil
    }

    // Helper method specifically intended to extract NonCore component names from builder declarations
    func nonCoreGenericType() -> Type? {
        if let primaryClass = self.typeInheritanceList.first {
            let parentClassTypeNames = primaryClass.names

            if let parentClassTypeNameFirst = parentClassTypeNames.first {
                if parentClassTypeNameFirst.name.textDescription == "NeedleFoundation"
                    || parentClassTypeNameFirst.name.textDescription == "Presidio",
                    parentClassTypeNames.count > 1 {
                    // Return the type name *after* the initial namespace scope
                    if let lastArg = parentClassTypeNames[1].genericArgumentClause?.argumentList.last,
                        lastArg.textDescription.contains("NonCore") {
                        return lastArg
                    }
                } else {
                    if let lastArg = parentClassTypeNameFirst.genericArgumentClause?.argumentList.last,
                        lastArg.textDescription.contains("NonCore") {
                        return lastArg
                    }
                }
            }
        }
        return nil
    }
}
