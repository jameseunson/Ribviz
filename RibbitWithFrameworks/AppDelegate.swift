//
//  AppDelegate.swift
//  Ribbit
//
//  Created by James Eunson on 9/2/18.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var rootWindowController: RootWindowControllable!

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        guard let windowController = NSApplication.shared.mainWindow?.windowController,
            let applicationWindowController = windowController as? RootWindowControllable else {
            abort()
        }

        rootWindowController = applicationWindowController
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @IBAction func menuDidSelectCloseProject(_ sender: Any) {
        rootWindowController.closeProject()
    }
}

