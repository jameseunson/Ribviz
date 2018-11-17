//
//  InteractiveConstraintBasedTextView.swift
//  RibbitWithFrameworks
//
//  Created by James Eunson on 9/8/18.
//  Copyright © 2018 Uber. All rights reserved.
//

import Foundation
import Cocoa

protocol InteractiveConstraintBasedTextViewListener: class {
    func didTapTextView()
}

class InteractiveConstraintBasedTextView: ConstraintBasedTextView {
    private var trackingArea: NSTrackingArea!
    private let hoverColor: NSColor = NSColor.red
    private let defaultColor: NSColor = NSColor.labelColor

    weak var listener: InteractiveConstraintBasedTextViewListener?

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    init() {
        super.init(frame: .zero)
    }

    override init(frame frameRect: NSRect, textContainer container: NSTextContainer?) {
        super.init(frame: frameRect, textContainer: container)
    }

    override func updateTrackingAreas() {
        if let trackingArea = self.trackingArea {
            self.removeTrackingArea(trackingArea)
        }

        trackingArea = NSTrackingArea(rect: frame, options: [.mouseEnteredAndExited, .activeAlways], owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }

    override func mouseEntered(with event: NSEvent) {
        self.textColor = hoverColor
    }

    override func mouseExited(with event: NSEvent) {
        self.textColor = defaultColor
    }

    override func mouseUp(with event: NSEvent) {
        listener?.didTapTextView()
    }
}
