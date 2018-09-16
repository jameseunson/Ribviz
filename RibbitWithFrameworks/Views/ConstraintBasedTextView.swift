//
//  ConstraintBasedTextView.swift
//  RibbitWithFrameworks
//
//  Created by James Eunson on 9/8/18.
//  Copyright © 2018 Uber. All rights reserved.
//

import Foundation
import Cocoa

class ConstraintBasedTextView: NSTextView {

    var cachedContentSize: NSSize?

    override var intrinsicContentSize: NSSize {
        if let cached = cachedContentSize {
            return cached
        }

        guard let textContainer = textContainer,
            let manager = textContainer.layoutManager else {
                return .zero
        }

        manager.ensureLayout(for: textContainer)

        let rect = manager.usedRect(for: textContainer)
        if !rect.equalTo(CGRect.zero) {
            cachedContentSize = rect.size
        }

        return rect.size
    }

    override func didChangeText() {
        super.didChangeText()
        invalidateIntrinsicContentSize()
    }
}

extension ConstraintBasedTextView {
    func applyDefault() {
        isEditable = false
        isSelectable = false
        backgroundColor = NSColor.clear
        textContainer?.maximumNumberOfLines = 1
    }
}
