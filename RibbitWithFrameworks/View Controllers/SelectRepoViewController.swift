//
//  SelectRepoViewController.swift
//  RibbitWithFrameworks
//
//  Created by James Eunson on 9/17/18.
//  Copyright © 2018 Uber. All rights reserved.
//

import Foundation
import Cocoa

protocol SelectRepoViewControllerListener: class {
    func didTapSelectDirectory()
}

class SelectRepoViewController: NSViewController {

    weak var listener: SelectRepoViewControllerListener?

    @IBAction func didTapSelectDirectoryButton(_ sender: Any) {
        listener?.didTapSelectDirectory()
    }
}
