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

class BuilderView : NSView, BuilderTableViewDelegateListener {

    public let builder: Builder
    private let label: ConstraintBasedTextView

    private let requiredLabel: ConstraintBasedTextView
    private let builtLabel: ConstraintBasedTextView

    private let componentTableView: ConstraintBasedTableView
    private let componentDelegate: BuilderTableViewDelegate
    private let componentDataSource: BuilderBuiltDependenciesDataSource

    private let dependencyTableView: ConstraintBasedTableView
    private let dependencyDelegate: BuilderTableViewDelegate
    private let dependencyDataSource: BuilderRequiredDependenciesDataSource

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
        addSubview(label)

        requiredLabel.applyDefault()
        requiredLabel.font = NSFont.systemFont(ofSize: 12, weight: .bold)
        requiredLabel.string = "Required"
        addSubview(requiredLabel)

        builtLabel.applyDefault()
        builtLabel.font = NSFont.systemFont(ofSize: 12, weight: .bold)
        builtLabel.string = "Built"
        addSubview(builtLabel)
    }

    func setupTableViews() {

        componentTableView.delegate = componentDelegate
        componentTableView.dataSource = componentDataSource
        componentTableView.backgroundColor = NSColor.clear
        componentTableView.usesAutomaticRowHeights = true
        addSubview(componentTableView)

        dependencyTableView.delegate = dependencyDelegate
        dependencyTableView.dataSource = dependencyDataSource
        dependencyTableView.backgroundColor = NSColor.clear
        dependencyTableView.usesAutomaticRowHeights = true
        addSubview(dependencyTableView)
    }

    func setupConstraints() {
        label.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview().inset(10)
            maker.left.right.equalToSuperview().inset(10)
        }

        builtLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(label.snp.bottom).offset(10)
            maker.left.equalTo(componentTableView.snp.left)
            maker.right.equalTo(componentTableView.snp.right)
        }

        requiredLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(label.snp.bottom).offset(10)
            maker.right.equalToSuperview()
            maker.left.equalTo(dependencyTableView.snp.left)
        }

        componentTableView.snp.makeConstraints { (maker) in
            maker.top.equalTo(builtLabel.snp.bottom).offset(10)
            maker.bottom.left.equalToSuperview().inset(10)
        }

        dependencyTableView.snp.makeConstraints { (maker) in
            maker.top.equalTo(requiredLabel.snp.bottom).offset(10)
            maker.bottom.right.equalToSuperview().inset(10)
            maker.left.equalTo(componentTableView.snp.right).inset(10)
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
}
