//
//  RootWindowDelegate.swift
//  RibbitWithFrameworks
//
//  Created by James Eunson on 11/24/18.
//  Copyright © 2018 Uber. All rights reserved.
//

import Foundation
import Cocoa

protocol RootWindowDelegateListener: class {
    func didAttemptClose()

    var shouldAllowClose: Bool { get }
}

class RootWindowDelegate: NSObject, NSWindowDelegate {

    weak var listener: RootWindowDelegateListener?

    // Application handles closing on tab basis, not as a window
    func windowShouldClose(_ sender: NSWindow) -> Bool {

        // Evaluated prior to didAttemptClose, otherwise when didAttemptClose()
        // triggers tab to close, the window will disappear also
        let shouldAllowClose = listener?.shouldAllowClose ?? false
        listener?.didAttemptClose()

        return shouldAllowClose
    }
}
