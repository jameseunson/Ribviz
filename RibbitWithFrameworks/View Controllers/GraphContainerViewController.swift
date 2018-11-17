//
//  GraphContainerViewController.swift
//  RibbitWithFrameworks
//
//  Created by James Eunson on 9/15/18.
//  Copyright © 2018 Uber. All rights reserved.
//

import Cocoa
import SnapKit
import AST
import KPCTabsControl
import RxSwift

protocol GraphContainerViewControllable: class {
    func filterVisibleGraphBy(query: String)
    func closeProject()
    func showFilteredGraph(dep: Dependency)
}

class GraphContainerViewController: NSViewController, GraphContainerViewControllable, SelectRepoViewControllerListener {
    
    @IBOutlet weak var tabsControl: TabsControl!
    @IBOutlet weak var contentView: NSView!

    private let parser: RibbitParser
    private let fileSystemHelper: RepoFileSystemHelper
    private var builders: [[Builder]]!

    private var graphs = [ Graph ]()
    private var graphControllers = [ GraphViewController ]()
    @IBOutlet weak var loadingView: NSProgressIndicator!

    private var visibleGraphViewController: GraphViewController!
    private var selectRepoViewController: SelectRepoViewController!

    private let disposeBag = DisposeBag()

    weak var listener: GraphViewControllerListener?

    @IBOutlet weak var tabsControlHeight: NSLayoutConstraint!

    required init?(coder: NSCoder) {
        parser = RibbitParser()
        fileSystemHelper = RepoFileSystemHelper()
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        tabsControl.dataSource = self
        tabsControl.delegate = self
        tabsControl.style = SafariStyle()
        didUpdateTabs()

        if let controller = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil).instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "SelectRepoViewController")) as? SelectRepoViewController {

            controller.listener = self
            selectRepoViewController = controller
        }

        if let url = fileSystemHelper.loadURLBookmark() {
            loadGraph(url: url)

        } else {
            displaySelectRepoController()
        }
    }

    private func addGraph(dep: Dependency? = nil) {

        if let controller = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil).instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "GraphViewController")) as? GraphViewController {

            controller.builders = builders
            controller.filterDependency = dep

            addChildViewController(controller)
            contentView.addSubview(controller.view)
            controller.view.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }

            controller.listener = self

            graphControllers.append(controller)
            graphs.append(controller.graph)

            tabsControl.reloadTabs()
            tabsControl.selectItemAtIndex(graphs.count - 1)
            didUpdateTabs()

            // This ensures the intrinsicContentSize of GraphView is available
            // prior to setting the NSScrollView document size.
            // Probably a better way of doing this.
            controller.graphView.layoutSubtreeIfNeeded()
            controller.view.layoutSubtreeIfNeeded()
        }
    }

    private func loadGraph(url: URL?) {
        guard let url = url else {
            self.displayGenericError()
            return
        }

        DispatchQueue.main.async {

            self.parser.progress
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { (progress: Double) in
                    self.loadingView.doubleValue = progress * 100
                })
                .disposed(by: self.disposeBag)

            DispatchQueue.global(qos: .userInitiated).async {
                self.builders = self.parser.retrieveBuilders(url: url)

                DispatchQueue.main.async {
                    self.addGraph()
                }
            }
        }
    }

    private func displaySelectRepoController() {

        childViewControllers.forEach { (viewController: NSViewController) in
            viewController.removeFromParentViewController()
            viewController.view.removeFromSuperview()
        }

        addChildViewController(selectRepoViewController)
        contentView.addSubview(selectRepoViewController.view)
        selectRepoViewController.view.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
    }

    // MARK: - SelectRepoViewControllerListener
    func didTapSelectDirectory() {

        fileSystemHelper
            .selectRepoDirectory()
            .subscribe(onNext: { (url: URL?) in

                if let url = url {
                    self.loadGraph(url: url)
                }

                self.selectRepoViewController?.removeFromParentViewController()
                self.selectRepoViewController?.view.removeFromSuperview()

            }, onError: { (error: Error) in
                self.displayGenericError()
            })
            .disposed(by: disposeBag)
    }

    private func displayGenericError() {
        NSAlert.displayError(messageText: "Error selecting directory", informativeText: "Specified directory could not be opened. Please check your permissions and try again.")
    }

    // MARK: - GraphContainerViewControllable
    func filterVisibleGraphBy(query: String) {
        visibleGraphViewController.filterVisibleGraphBy(query: query)
    }

    func closeProject() {
        let result = fileSystemHelper.removeBookmark()
        guard result else {
            if let urlString = fileSystemHelper.loadURLBookmark()?.absoluteString {
                NSAlert.displayError(messageText: "Error closing project", informativeText: "Please check file permissions for \(urlString) and try again.")
            } else {
                NSAlert.displayError(messageText: "Error closing project", informativeText: "Please check your file permissions and try again.")
            }
            return
        }

        displaySelectRepoController()
    }

    func showFilteredGraph(dep: Dependency) {
        addGraph(dep: dep)
    }

    // MARK: - Target Action
    @objc func closeTab(sender: NSMenuItem) {
        print("closeTab")

        let controller = graphControllers[sender.tag]

        controller.removeFromParentViewController()
        controller.view.removeFromSuperview()

        if let index = graphControllers.index(of: controller) {
            graphControllers.remove(at: index)
        }

        // TODO: Remove graph
        tabsControl.reloadTabs()
        tabsControl.selectItemAtIndex(graphControllers.count-1)
        didUpdateTabs()
    }

    // MARK: - Private
    func didUpdateTabs() {
        let hideTabs = graphControllers.count <= 1

        tabsControl.isHidden = hideTabs
        tabsControlHeight.constant = hideTabs ? 0 : 30
    }
}

extension GraphContainerViewController: TabsControlDelegate {
    func tabsControlDidChangeSelection(_ control: TabsControl, item: AnyObject) {

        let index = graphs.index { (graph: Graph) -> Bool in
            guard let item = item as? Graph else {
                return false
            }
            return graph === item
        }
        guard let idx = index else {
            return
        }

        var i = 0
        for controller in graphControllers {
            if i == idx {
                controller.view.isHidden = false
                visibleGraphViewController = controller

            } else {
                controller.view.isHidden = true
            }

            i = i + 1
        }
    }
}

extension GraphContainerViewController: TabsControlDataSource {
    func tabsControlNumberOfTabs(_ control: TabsControl) -> Int {
        return graphControllers.count
    }

    func tabsControl(_ control: TabsControl, titleForItem item: AnyObject) -> String {
        if let graph = item as? Graph {
            return graph.displayName
        }
        return "Unknown"
    }

    func tabsControl(_ control: TabsControl, itemAtIndex index: Int) -> Swift.AnyObject {
        return graphControllers[index].graph
    }

    func tabsControl(_ control: TabsControl, menuForItem item: AnyObject) -> NSMenu? {
        guard let graph = item as? Graph else {
            return nil
        }
        let index = graphs.index { (g: Graph) -> Bool in
            return g === graph
        }
        guard let idx = index else {
            return nil
        }

        if idx == 0 {
            return nil
        }

        let menu = NSMenu.init()
        let menuItem = NSMenuItem.init(title: "Close Tab", action: #selector(closeTab(sender:)), keyEquivalent: "C")
        menuItem.target = self
        menuItem.isEnabled = true
        menuItem.tag = idx
        menu.addItem(menuItem)

        return menu
    }

    func tabsControl(_ control: TabsControl, iconForItem item: AnyObject) -> NSImage? {
        return nil
    }

    func tabsControl(_ control: TabsControl, titleAlternativeIconForItem item: AnyObject) -> NSImage? {
        return nil
    }
}

class TabObject {}

extension GraphContainerViewController: GraphViewControllerListener {
    func didSelectItem(dep: Dependency) {
        listener?.didSelectItem(dep: dep)
    }
}
