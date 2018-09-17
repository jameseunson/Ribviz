//
//  NSAlert+Compact.swift
//  RibbitWithFrameworks
//
//  Created by James Eunson on 9/17/18.
//  Copyright © 2018 Uber. All rights reserved.
//

import Foundation
import Cocoa

extension NSAlert {
    static func displayError(style: NSAlert.Style = .critical, messageText: String, informativeText: String) {
        let alert = NSAlert()
        alert.alertStyle = style
        alert.messageText = messageText
        alert.informativeText = informativeText
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
