//
//  RibVizTabStyle.swift
//  RibbitWithFrameworks
//
//  Created by James Eunson on 11/24/18.
//  Copyright © 2018 Uber. All rights reserved.
//

import Foundation
import KPCTabsControl
import AppKit

// Unfortunately largely lifted from here, with modifications due to struct requirement for theme
// https://github.com/jameseunson/KPCTabsControl/blob/master/KPCTabsControl/SafariTheme.swift
public struct RibVizTabTheme: Theme {

    public static var isDarkMode: Bool = false

    public init() {}

    public let tabButtonTheme: TabButtonTheme = DefaultTabButtonTheme()
    public let selectedTabButtonTheme: TabButtonTheme = SelectedTabButtonTheme()
    public let unselectableTabButtonTheme: TabButtonTheme = UnselectableTabButtonTheme(base: DefaultTabButtonTheme())
    public let tabsControlTheme: TabsControlTheme = DefaultTabsControlTheme()

    public static var sharedBackgroundColor: NSColor {
        return isDarkMode ? NSColor(white: 1 - 0.72, alpha: 1.0) : NSColor(white: 0.72, alpha: 1.0)
    }
    public static var sharedBorderColor: NSColor {
        return isDarkMode ? NSColor(white: 1 - 0.61, alpha: 1.0) : NSColor(white: 0.61, alpha: 1.0)
    }

    fileprivate struct DefaultTabButtonTheme: KPCTabsControl.TabButtonTheme {
        var backgroundColor: NSColor { return RibVizTabTheme.sharedBackgroundColor }
        var borderColor: NSColor { return RibVizTabTheme.sharedBorderColor }
        var titleColor: NSColor { return NSColor(white: 0.38, alpha: 1.0) }
        var titleFont: NSFont { return NSFont.systemFont(ofSize: NSFont.systemFontSize) }
    }

    fileprivate struct SelectedTabButtonTheme: KPCTabsControl.TabButtonTheme {
        var backgroundColor: NSColor {
            return isDarkMode ? NSColor(white: 1 - 0.79, alpha: 1.0) : NSColor(white: 0.79, alpha: 1.0)
        }
        var borderColor: NSColor {
            return isDarkMode ? NSColor(white: 1 - 0.64, alpha: 1.0) : NSColor(white: 0.64, alpha: 1.0)
        }
        var titleColor: NSColor {
            return isDarkMode ? NSColor(white: 1 - 0.08, alpha: 1.0) : NSColor(white: 0.08, alpha: 1.0)
        }
        var titleFont: NSFont { return NSFont.systemFont(ofSize: NSFont.systemFontSize) }
    }

    fileprivate struct UnselectableTabButtonTheme: KPCTabsControl.TabButtonTheme {
        let base: DefaultTabButtonTheme

        var backgroundColor: NSColor { return base.backgroundColor }
        var borderColor: NSColor { return base.borderColor }
        var titleColor: NSColor { return isDarkMode ? NSColor(white: 1 - 0.94, alpha: 1.0) : NSColor(white: 0.94, alpha: 1.0) }
        var titleFont: NSFont { return base.titleFont }
    }

    fileprivate struct DefaultTabsControlTheme: KPCTabsControl.TabsControlTheme {
        var backgroundColor: NSColor { return RibVizTabTheme.sharedBackgroundColor }
        var borderColor: NSColor { return RibVizTabTheme.sharedBorderColor }
    }
}
