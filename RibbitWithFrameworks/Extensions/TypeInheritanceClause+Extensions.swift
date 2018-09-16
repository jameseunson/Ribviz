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
        if let primaryClass = self.typeInheritanceList.first,
            let parentClassTypeName = primaryClass.names.first?.name.textDescription {
            return parentClassTypeName
        }
        return nil
    }

    func primaryGenericType() -> Type? {
        if let primaryClass = self.typeInheritanceList.first,
            let parentClassGenericType = primaryClass.names.first?.genericArgumentClause?.argumentList.first {
            return parentClassGenericType
        }
        return nil
    }
}
