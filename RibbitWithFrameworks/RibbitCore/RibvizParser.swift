//
//  main.swift
//  Ribbit
//
//  Created by James Eunson on 8/17/18.
//  Copyright © 2018 Uber. All rights reserved.
//

import Foundation
import AST
import Parser
import Source
import RxSwift

class RibvizParser {

    private static let queueName = "com.uber.Ribviz.parserQueue"

    private let resourceKeys : [URLResourceKey] = [.creationDateKey, .isDirectoryKey]

    private let componentParser = ComponentParser()
    private let pluginPointParser = PluginPointParser()

    private let progressSubject = PublishSubject<Double>()

    let progress: Observable<Double>

    private let parserQueue = DispatchQueue(label: RibvizParser.queueName, attributes: .concurrent)

    private let builderGroup = DispatchGroup()
    private let componentGroup = DispatchGroup()
    private let pluginPointGroup = DispatchGroup()

    private let disposeBag = DisposeBag()

    private var currentFileIndex = 0
    private var totalFileCount = 0
    private var builders = [Builder]()

    init() {
        progress = progressSubject.asObservable()
    }

    public func retrieveBuilders(url: URL) -> Observable<[[Builder]]?> {

        let levelOrderBuildersSubject = PublishSubject<[[Builder]]?>()

        let url = url.standardizedFileURL.resolvingSymlinksInPath()
        totalFileCount = determineFileCount(from: url)
        progressSubject.onNext(0)

        extractBuilders(from: url)
            .flatMapFirst { (builders: [Builder]) -> Observable<()> in
                return self.extractComponents(from: url)
            }
            .flatMapFirst { (_: ()) -> Observable<()> in
                return self.extractPluginPoints(from: url)
            }
            .subscribe(onNext: { _ in

                // Extract non-core components and apply to corresponding builders
//                self.extractPluginFactories(from: url)

                let hierarchicalBuilders = self.builders.createHierarchy()
                let levelOrderBuilders = hierarchicalBuilders.createLevelOrderBuilders()

                levelOrderBuildersSubject.onNext(levelOrderBuilders)
            })
            .disposed(by: disposeBag)

        return levelOrderBuildersSubject.asObservable()
    }

    // MARK: - Builders

    func generateBuilderWorkItems(from path: URL) -> [DispatchWorkItem] {
        var workItems = [DispatchWorkItem]()

        guard let enumerator = createEnumerator(from: path) else {
            return workItems
        }

        for case let fileURL as URL in enumerator {
            guard fileURL.path.contains("Builder.swift") else { continue }

            let workItem = DispatchWorkItem {
                self.builderGroup.enter()

                let parser = BuilderParser()
                var parsedBuilders: [ Builder ]?
                do {
                    parsedBuilders = try parser.parse(fileURL: fileURL)
                } catch {
                    print(error)
                }

                if let parsedBuilders = parsedBuilders {
                    self.builders.append(contentsOf: parsedBuilders)
                }

                self.incrementFileCount()
                self.builderGroup.leave()
            }
            workItems.append(workItem)
        }

        return workItems
    }

    private func extractBuilders(from path: URL) -> Observable<[Builder]> {

        let builderSubject = PublishSubject<[Builder]>()

        let workItems = generateBuilderWorkItems(from: path)
        for item in workItems {
            parserQueue.async(execute: item)
        }

        builderGroup.notify(queue: DispatchQueue.main) {
            builderSubject.onNext(self.builders)
        }

        return builderSubject.asObservable()
    }

    // MARK: - Components
   func generateComponentWorkItems(from path: URL) -> [DispatchWorkItem] {

        var workItems = [DispatchWorkItem]()
        guard let enumerator = createEnumerator(from: path) else { return workItems }

        for case let fileURL as URL in enumerator {
            guard fileURL.path.contains("NonCoreComponent.swift") else { continue }

            let workItem = DispatchWorkItem {
                self.componentGroup.enter()

                do {
                    try self.componentParser.parse(fileURL: fileURL, applyTo: self.builders)
                } catch {
                    print(error)
                }

                self.incrementFileCount()
                self.componentGroup.leave()
            }
            workItems.append(workItem)
        }

        return workItems
    }

    private func extractComponents(from path: URL) -> Observable<()> {

        let componentSubject = PublishSubject<()>()

        let workItems = generateComponentWorkItems(from: path)
        for item in workItems {
            parserQueue.async(execute: item)
        }

        componentGroup.notify(queue: DispatchQueue.main) {
            componentSubject.onNext(())
        }
        return componentSubject.asObservable()
    }

    // MARK: - Plugin Points
    func generatePluginPointWorkItems(from path: URL) -> [DispatchWorkItem] {

        var workItems = [DispatchWorkItem]()
        guard let enumerator = createEnumerator(from: path) else { return workItems }

        for case let fileURL as URL in enumerator {
            guard fileURL.path.contains("PluginPoint.swift") else { continue }

            let workItem = DispatchWorkItem {
                self.pluginPointGroup.enter()

                do {
                    try self.pluginPointParser.parse(fileURL: fileURL)
                } catch {
                    print(error)
                }

                self.incrementFileCount()
                self.pluginPointGroup.leave()
            }
            workItems.append(workItem)
        }

        return workItems
    }

    private func extractPluginPoints(from path: URL) -> Observable<()> {
        let pluginPointSubject = PublishSubject<()>()

        let workItems = generatePluginPointWorkItems(from: path)
        for item in workItems {
            parserQueue.async(execute: item)
        }

        pluginPointGroup.notify(queue: DispatchQueue.main) {
            pluginPointSubject.onNext(())
        }
        return pluginPointSubject.asObservable()
    }

    // MARK: - Plugin Factories
    private func extractPluginFactories(from path: URL) {
        if let enumerator = FileManager.default.enumerator(at: path, includingPropertiesForKeys: resourceKeys, options: [.skipsHiddenFiles], errorHandler: { (url, error) -> Bool in
            print("directoryEnumerator error ast \(url): ", error)

            return true
        }) {
            for case let fileURL as URL in enumerator {
                guard fileURL.path.contains("PluginFactory.swift") else { continue }

                if fileURL.path.contains("PluginFactory.swift") {
                }
                incrementFileCount()
            }
        }
    }

    // MARK: - Private
    private func determineFileCount(from path: URL) -> Int {

        var totalFileCount = 0

        // First enumeration to establish how many files there are
        if let countEnumerator = FileManager.default.enumerator(at: path, includingPropertiesForKeys: resourceKeys, options: [.skipsHiddenFiles], errorHandler: { (url, error) -> Bool in return true }) {
            for case let fileURL as URL in countEnumerator {
                if fileURL.path.contains("Builder.swift") ||
                    fileURL.path.contains("Component.swift") ||
                    fileURL.path.contains("PluginPoint.swift") ||
                    fileURL.path.contains("PluginFactory.swift") {
                    totalFileCount = totalFileCount + 1
                }
            }
        }

        return totalFileCount
    }

    private func incrementFileCount() {
        self.currentFileIndex = self.currentFileIndex + 1
        self.progressSubject.onNext(Double(self.currentFileIndex) / Double(self.totalFileCount))
    }

    private func createEnumerator(from path: URL) -> FileManager.DirectoryEnumerator? {
        return FileManager.default.enumerator(at: path, includingPropertiesForKeys: resourceKeys, options: [.skipsHiddenFiles], errorHandler: { (url, error) -> Bool in
            print("directoryEnumerator error ast \(url): ", error)

            return true
        })
    }
}
