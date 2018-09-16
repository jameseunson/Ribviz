//
//  BuilderView.swift
//  RibbitWithFrameworks
//
//  Created by James Eunson on 9/8/18.
//  Copyright © 2018 Uber. All rights reserved.
//

import Foundation
import Cocoa

protocol BuilderViewListener: class {
    func didSelectItem(dep: Dependency)
}

protocol BuilderViewable: class {
    func filterBy(query: String)
}

class BuilderView : NSView, BuilderTableViewDelegateListener {

    public let builder: Builder
    public var filteredDependency: Dependency? {
        didSet {
            componentDataSource.filteredDependency = filteredDependency
            dependencyDataSource.filteredDependency = filteredDependency

            componentTableView.reloadData()
            dependencyTableView.reloadData()

            let componentMissing = componentDataSource.numberOfRows(in: componentTableView) == 0
            componentTableView.isHidden = componentMissing
            builtLabel.isHidden = componentMissing

            let dependencyMissing = dependencyDataSource.numberOfRows(in: dependencyTableView) == 0
            dependencyTableView.isHidden = dependencyMissing
            requiredLabel.isHidden = dependencyMissing
        }
    }

    var highlightQuery: String? {
        didSet {
            componentDelegate.highlightQuery = highlightQuery
            dependencyDelegate.highlightQuery = highlightQuery

            componentTableView.reloadData()
            dependencyTableView.reloadData()
        }
    }

    private let label: ConstraintBasedTextView

    private let requiredLabel: ConstraintBasedTextView
    private let builtLabel: ConstraintBasedTextView

    private let componentTableView: ConstraintBasedTableView
    private let componentDelegate: BuilderTableViewDelegate
    private let componentDataSource: BuilderBuiltDependenciesDataSource

    private let dependencyTableView: ConstraintBasedTableView
    private let dependencyDelegate: BuilderTableViewDelegate
    private let dependencyDataSource: BuilderRequiredDependenciesDataSource

    private let tableViewStackView: NSStackView
    private let labelStackView: NSStackView

    private let titleHorizontalRuleView: NSView
    private let subtitleHorizontalRuleView: NSView

    weak var listener: BuilderViewListener?

    required init?(coder decoder: NSCoder) {
        fatalError("Not implemented")
    }

    init(builder: Builder) {

        self.builder = builder
        label = ConstraintBasedTextView()
        requiredLabel = ConstraintBasedTextView()
        builtLabel = ConstraintBasedTextView()

        componentTableView = ConstraintBasedTableView()
        componentDelegate = BuilderTableViewDelegate(builder: builder)
        componentDataSource = BuilderBuiltDependenciesDataSource(builder: builder)

        dependencyTableView = ConstraintBasedTableView()
        dependencyDelegate = BuilderTableViewDelegate(builder: builder)
        dependencyDataSource = BuilderRequiredDependenciesDataSource(builder: builder)

        titleHorizontalRuleView = NSView()
        subtitleHorizontalRuleView = NSView()

        tableViewStackView = NSStackView()
        labelStackView = NSStackView()

        tableViewStackView.distribution = .fillEqually
        labelStackView.distribution = .fillEqually

        super.init(frame: .zero)

        wantsLayer = true

        layer?.backgroundColor = NSColor.white.cgColor
        layer?.cornerRadius = 10
        layer?.borderColor = NSColor(white: 0, alpha: 0.15).cgColor
        layer?.borderWidth = 1

        translatesAutoresizingMaskIntoConstraints = false

        titleHorizontalRuleView.wantsLayer = true
        titleHorizontalRuleView.layer?.backgroundColor = NSColor(white: 0, alpha: 0.15).cgColor
        addSubview(titleHorizontalRuleView)

        subtitleHorizontalRuleView.wantsLayer = true
        subtitleHorizontalRuleView.layer?.backgroundColor = NSColor(white: 0, alpha: 0.15).cgColor
        addSubview(subtitleHorizontalRuleView)

        addSubview(tableViewStackView)
        addSubview(labelStackView)

        componentDelegate.listener = self
        dependencyDelegate.listener = self

        setupLabels()
        setupTableViews()
        setupConstraints()
    }

    func setupLabels() {

        label.applyDefault()
        label.font = NSFont.systemFont(ofSize: 14, weight: .bold)
        label.string = builder.name
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        addSubview(label)

        requiredLabel.applyDefault()
        requiredLabel.font = NSFont.systemFont(ofSize: 12, weight: .bold)
        requiredLabel.string = "Required"
        labelStackView.addArrangedSubview(requiredLabel)

        builtLabel.applyDefault()
        builtLabel.font = NSFont.systemFont(ofSize: 12, weight: .bold)
        builtLabel.string = "Built"
        labelStackView.addArrangedSubview(builtLabel)
    }

    func setupTableViews() {

        componentTableView.delegate = componentDelegate
        componentTableView.dataSource = componentDataSource
        componentTableView.backgroundColor = NSColor.clear
        componentTableView.usesAutomaticRowHeights = true
        tableViewStackView.addArrangedSubview(componentTableView)

        dependencyTableView.delegate = dependencyDelegate
        dependencyTableView.dataSource = dependencyDataSource
        dependencyTableView.backgroundColor = NSColor.clear
        dependencyTableView.usesAutomaticRowHeights = true
        tableViewStackView.addArrangedSubview(dependencyTableView)
    }

    func setupConstraints() {
        label.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview().inset(10)
            maker.left.right.equalToSuperview().inset(10)
        }

        labelStackView.snp.makeConstraints { (maker) in
            maker.top.equalTo(label.snp.bottom).offset(10)
            maker.right.left.equalToSuperview().inset(10)
        }

        tableViewStackView.snp.makeConstraints { (maker) in
            maker.top.equalTo(labelStackView.snp.bottom).offset(10)
            maker.bottom.right.left.equalToSuperview().inset(10)
        }

        titleHorizontalRuleView.snp.makeConstraints { (maker) in
            maker.top.equalTo(label.snp.bottom).offset(5)
            maker.height.equalTo(1)
            maker.left.right.equalToSuperview()
        }

        subtitleHorizontalRuleView.snp.makeConstraints { (maker) in
            maker.top.equalTo(builtLabel.snp.bottom).offset(5)
            maker.height.equalTo(1)
            maker.left.right.equalToSuperview()
        }
    }

    // MARK: - BuilderTableRowViewListener
    func didSelectItem(dep: Dependency) {
        listener?.didSelectItem(dep: dep)
    }

    // MARK: - BuilderViewable
    func filterBy(query: String) {
        highlightQuery = query
    }
}
