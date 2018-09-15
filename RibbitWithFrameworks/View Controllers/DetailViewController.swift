//
//  DetailViewController.swift
//  RibbitWithFrameworks
//
//  Created by James Eunson on 9/8/18.
//  Copyright © 2018 Uber. All rights reserved.
//

import Foundation
import Cocoa
import AST

class DetailViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {

    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var subtitleLabel: NSTextField!

    @IBOutlet weak var tableSubtitleLabel: NSTextField!
    @IBOutlet weak var depButton: NSButton!

    private let tableView: ConstraintBasedTableView

    required init?(coder: NSCoder) {
        tableView = ConstraintBasedTableView()
        super.init(coder: coder)
    }

    var detailItem: Dependency? {
        didSet {
            guard let detailItem = detailItem else {
                return
            }
            if case let AST.ProtocolDeclaration.Member.property(member) = detailItem.dependency {
                 titleLabel.stringValue = member.typeAnnotation.type.textDescription
            }
            subtitleLabel.stringValue = detailItem.builder.name
            tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = NSColor.clear
        tableView.intercellSpacing = NSSize(width: 0, height: 4)

        tableView.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview().offset(10)
            maker.top.equalTo(tableSubtitleLabel.snp.bottom).offset(20)
            maker.height.greaterThanOrEqualTo(500)
        }
    }

    // MARK: - NSTableViewDataSource
    public func numberOfRows(in tableView: NSTableView) -> Int {
        return detailItem?.usedIn?.count ?? 0
    }

    public func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return detailItem?.usedIn?[row]
    }

    // MARK: - NSTableViewDelegate
    func tableView(_ tableView: NSTableView, dataCellFor tableColumn: NSTableColumn?, row: Int) -> NSCell? {
        return nil
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        return nil
    }

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        guard let dep = tableView.dataSource?.tableView?(tableView, objectValueFor: nil, row: row) as? Builder else {
            return nil
        }
        let row = DetailTableViewRow(dep: dep)
        return row
    }
}

class DetailTableViewRow: NSTableRowView {
    required init?(coder decoder: NSCoder) {
        fatalError("Not implemented")
    }

    private let dep: Builder
    private let label: InteractiveConstraintBasedTextView

    init(dep: Builder) {
        label = InteractiveConstraintBasedTextView()
        self.dep = dep
        super.init(frame: .zero)

        label.applyDefault()
        label.font = NSFont.systemFont(ofSize: 14)

        addSubview(label)

        label.string = dep.name

        label.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
    }

    override var intrinsicContentSize: NSSize {
        return NSSize(width: label.intrinsicContentSize.width, height: -1)
    }
}
