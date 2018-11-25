//
//  AppDelegate.swift
//  Ribbit
//
//  Created by James Eunson on 9/2/18.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {}

    func applicationWillTerminate(_ aNotification: Notification) {}

    @IBAction func menuDidSelectCloseProject(_ sender: Any) {
        if let windowController = NSApplication.shared.mainWindow?.windowController,
            let applicationWindowController = windowController as? RootWindowControllable {
            applicationWindowController.closeProject()
        }
    }
}

