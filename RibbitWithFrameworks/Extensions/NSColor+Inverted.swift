//
//  NSColor+Inverted.swift
//  RibbitWithFrameworks
//
//  Created by James Eunson on 11/17/18.
//  Copyright © 2018 Uber. All rights reserved.
//

import Foundation
import Cocoa

extension NSColor {

    func inverted(alpha: CGFloat? = nil) -> NSColor? {

        var componentAlpha: CGFloat = 0
        if let alpha = alpha {
            componentAlpha = alpha
        } else {
            componentAlpha = alphaComponent
        }

        return NSColor(calibratedRed: 1.0 - redComponent,
                               green: 1.0 - greenComponent,
                               blue: 1.0 - blueComponent,
                               alpha: componentAlpha)
    }

    static var borderColor: NSColor {
        if let inverted = NSColor.windowBackgroundColor.usingColorSpace(.deviceRGB)?.inverted(alpha: 0.15) {
            return inverted
        } else {
            return NSColor(white: 0, alpha: 0.15)
        }
    }
}
