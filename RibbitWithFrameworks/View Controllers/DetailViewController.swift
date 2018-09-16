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

protocol DetailViewControllerListener: class {
    func didSelectDependencyGraphButton(dep: Dependency)
}

class DetailViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {

    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var subtitleLabel: NSTextField!
    @IBOutlet weak var depButton: NSButton!

    private let tableView: ConstraintBasedTableView

    weak var listener: DetailViewControllerListener?

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

            } else if let built = detailItem.builtProtocol {
                titleLabel.stringValue = built.textDescription
            }
            subtitleLabel.stringValue = detailItem.builder.name
            tableView.reloadData()

            titleLabel.isHidden = false
            subtitleLabel.isHidden = false
            depButton.isHidden = false
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
            maker.top.equalTo(depButton.snp.bottom).offset(20)
            maker.height.greaterThanOrEqualTo(500)
        }

        titleLabel.isHidden = true
        subtitleLabel.isHidden = true
        depButton.isHidden = true
    }
    @IBAction func didSelectDepButton(_ sender: Any) {
        if let detailItem = detailItem {
            listener?.didSelectDependencyGraphButton(dep: detailItem)
        }
    }

    // MARK: - NSTableViewDataSource
    public func numberOfRows(in tableView: NSTableView) -> Int {

        var count = 0
        if detailItem?.builtIn != nil {
            count += 2 // 1 for actual row, 1 for header
        }

        let usedIn = detailItem?.usedIn?.count ?? 0
        if usedIn > 0 {
            count += usedIn + 1 // 1 for actual row, 1 for header
        }

        return count
    }

    public func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if detailItem?.builtIn != nil {
            if row == 0 {
                return DetailHeaderSentinel(title: "Dependency built in")
            } else if row == 1 {
                return detailItem?.builtIn
            } else if row == 2 {
                return DetailHeaderSentinel(title: "Dependency used in")
            } else {
                return detailItem?.usedIn?[row-3]
            }

        } else {
            if row == 0 {
                return DetailHeaderSentinel(title: "Dependency used in")
            } else {
                return detailItem?.usedIn?[row-1]
            }
        }
    }

    // MARK: - NSTableViewDelegate
    func tableView(_ tableView: NSTableView, dataCellFor tableColumn: NSTableColumn?, row: Int) -> NSCell? {
        return nil
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        return nil
    }

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        guard let dep = tableView.dataSource?.tableView?(tableView, objectValueFor: nil, row: row) else {
            return nil
        }

        if let builder = dep as? Builder {
            return DetailTableViewRow(dep: builder)

        } else if let sentinel = dep as? DetailHeaderSentinel {
            return DetailTableHeaderViewRow(title: sentinel.title)
        }

        return nil
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

final class DetailHeaderSentinel {
    let title: String

    init(title: String) {
        self.title = title
    }
}

class DetailTableHeaderViewRow: NSTableRowView {
    required init?(coder decoder: NSCoder) {
        fatalError("Not implemented")
    }

    private let label: ConstraintBasedTextView

    init(title: String) {
        label = ConstraintBasedTextView()
        super.init(frame: .zero)

        label.applyDefault()
        label.font = NSFont.systemFont(ofSize: 14, weight: .bold)

        addSubview(label)

        label.string = title

        label.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
    }

    override var intrinsicContentSize: NSSize {
        return NSSize(width: label.intrinsicContentSize.width, height: -1)
    }
}
