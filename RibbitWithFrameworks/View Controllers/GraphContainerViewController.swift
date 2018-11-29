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
    func updateDisplayMode(_ mode: DisplayMode)
    func didAttemptClose()

    var shouldAllowClose: Bool { get }
}

protocol GraphContainerViewControllerListener: class {
    func didSelectItem(dep: Dependency?)
}

protocol GraphControllerProviding: class {
    var graphControllers: [GraphViewController] { get }
    var visibleGraphViewController: GraphViewController? { get set }
}

final class GraphControllerProvider: GraphControllerProviding {
    var graphControllers: [GraphViewController]
    var visibleGraphViewController: GraphViewController?
    init() {
        self.graphControllers = [ GraphViewController ]()
    }
}

class GraphContainerViewController: NSViewController, GraphContainerViewControllable, SelectRepoViewControllerListener, GraphContainerTabsControlDataSourceListener {

    weak var listener: GraphContainerViewControllerListener?

    @IBOutlet weak var tabsControl: TabsControl!
    @IBOutlet weak var contentView: NSView!

    private let parser: RibvizParser
    private let fileSystemHelper: RepoFileSystemHelper

    private let tabsDelegate: GraphContainerTabsControlDelegate
    private let tabsDataSource: GraphContainerTabsControlDataSource
    private var tabsTheme: RibVizTabTheme

    private let graphControllerProvider: GraphControllerProvider

    private var builders: [[Builder]] = [[Builder]]()

    private var selectRepoViewController: SelectRepoViewController!
    private let disposeBag = DisposeBag()

    @IBOutlet weak var loadingView: NSProgressIndicator!
    @IBOutlet weak var tabsControlHeight: NSLayoutConstraint!

    required init?(coder: NSCoder) {
        parser = RibvizParser()
        fileSystemHelper = RepoFileSystemHelper()
        graphControllerProvider = GraphControllerProvider()

        tabsDelegate = GraphContainerTabsControlDelegate(graphControllerProvider: graphControllerProvider)
        tabsDataSource = GraphContainerTabsControlDataSource(graphControllerProvider: graphControllerProvider)
        tabsTheme = RibVizTabTheme()

        super.init(coder: coder)
    }

    override func viewDidLoad() {

        RibVizTabTheme.isDarkMode = contentView.isDarkMode
        tabsDataSource.listener = self

        tabsControl.dataSource = tabsDataSource
        tabsControl.delegate = tabsDelegate

        tabsControl.style = SafariStyle(theme: tabsTheme)
        didUpdateTabs()

        if let controller = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
            .instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "SelectRepoViewController")) as? SelectRepoViewController {

            controller.listener = self
            selectRepoViewController = controller
        }

        // Find security scoped bookmark for target project directory
        if let url = fileSystemHelper.loadURLBookmark() {
            loadingView.isHidden = false
            loadGraph(url: url)

        } else {
            loadingView.isHidden = true

            // If non-existent, overlay view controller soliciting
            // user to provide target project directory
            displaySelectRepoController()
        }
    }

    private func addGraph(dep: Dependency? = nil) {

        guard let controller = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
            .instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "GraphViewController")) as? GraphViewController else {
            return
        }

//        if let filteredDep = dep,
//            let usedInBuilders = filteredDep.usedIn {
//            controller.builders = usedInBuilders
//
//        }

        controller.builders = builders
        controller.filterDependency = dep

        addChildViewController(controller)
        contentView.addSubview(controller.view)
        controller.view.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }

        controller.listener = self
        graphControllerProvider.graphControllers.append(controller)

        tabsControl.reloadTabs()

        let selectedIndex = graphControllerProvider.graphControllers.count-1
        tabsControl.selectItemAtIndex(selectedIndex)

        didUpdateTabs()

        // This ensures the intrinsicContentSize of GraphView is available
        // prior to setting the NSScrollView document size.
        // Probably a better way of doing this.
        controller.graphView.layoutSubtreeIfNeeded()
        controller.view.layoutSubtreeIfNeeded()
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
                self.parser.retrieveBuilders(url: url).subscribe(onNext: { (builders: [[Builder]]?) in
                    guard let builders = builders else {
                        return
                    }

                    self.builders = builders

                    self.loadingView.isHidden = true
                    self.addGraph()
                })
                .disposed(by: self.disposeBag)
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
                    self.loadingView.isHidden = false
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
        NSAlert.displayError(messageText: "Error selecting directory",
                             informativeText: "Specified directory could not be opened. Please check your permissions and try again.")
    }

    // MARK: - GraphContainerViewControllable
    var shouldAllowClose: Bool {
        return graphControllerProvider.graphControllers.count == 1
    }

    func filterVisibleGraphBy(query: String) {
        graphControllerProvider.visibleGraphViewController?.filterVisibleGraphBy(query: query)
    }

    func closeProject() {

        graphControllerProvider.graphControllers = []
        graphControllerProvider.visibleGraphViewController = nil

        tabsControl.reloadTabs()
        didUpdateTabs()

        loadingView.doubleValue = 0

        listener?.didSelectItem(dep: nil)

        let result = fileSystemHelper.removeBookmark()
        guard result else {
            if let urlString = fileSystemHelper.loadURLBookmark()?.absoluteString {
                NSAlert.displayError(messageText: "Error closing project",
                                     informativeText: "Please check file permissions for \(urlString) and try again.")
            } else {
                NSAlert.displayError(messageText: "Error closing project",
                                     informativeText: "Please check your file permissions and try again.")
            }
            return
        }

        displaySelectRepoController()
    }

    func showFilteredGraph(dep: Dependency) {
        addGraph(dep: dep)
    }

    func updateDisplayMode(_ mode: DisplayMode) {
        
    }

    func didAttemptClose() {
        guard !shouldAllowClose,
            let visibleViewController = graphControllerProvider.visibleGraphViewController else {
            return
        }

        let index = graphControllerProvider.graphControllers.index { (graphViewController: GraphViewController) -> Bool in
            return graphViewController === visibleViewController
        }
        guard let idx = index else {
            return
        }
        closeTab(index: idx)
    }

    // MARK: - Private
    func didUpdateTabs() {
        let hideTabs = graphControllerProvider.graphControllers.count <= 1

        tabsControl.isHidden = hideTabs
        tabsControlHeight.constant = hideTabs ? 0 : 30
    }

    // MARK: - GraphContainerTabsControlDataSourceListener
    func closeTab(index: Int) {
        let controller = graphControllerProvider.graphControllers[index]

        controller.removeFromParentViewController()
        controller.view.removeFromSuperview()

        if let index = graphControllerProvider.graphControllers.index(of: controller) {
            graphControllerProvider.graphControllers.remove(at: index)
        }

        tabsControl.reloadTabs()

        let selectedIndex = graphControllerProvider.graphControllers.count-1
        tabsControl.selectItemAtIndex(selectedIndex)
        graphControllerProvider.visibleGraphViewController = graphControllerProvider.graphControllers[selectedIndex]

        didUpdateTabs()
    }
}

class TabObject {}

extension GraphContainerViewController: GraphViewControllerListener {
    func didSelectItem(dep: Dependency) {
        listener?.didSelectItem(dep: dep)
    }
}

extension NSView {
    var isDarkMode: Bool {
        if #available(OSX 10.14, *) {
            if effectiveAppearance.name == .darkAqua {
                return true
            }
        }
        return false
    }
}
