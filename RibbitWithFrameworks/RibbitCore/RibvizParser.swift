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

    private let resourceKeys : [URLResourceKey] = [.creationDateKey, .isDirectoryKey]

    private let builderParser = BuilderParser()
    private let componentParser = ComponentParser()
    private let pluginPointParser = PluginPointParser()

    private let progressSubject = PublishSubject<Double>()
    private let progressFileSubject = PublishSubject<String>()

    let progress: Observable<Double>
    let progressFile: Observable<String>

    private var currentFileIndex = 0
    private var totalFileCount = 0

    init() {
        progress = progressSubject.asObservable()
        progressFile = progressFileSubject.asObservable()
    }

    public func retrieveBuilders(url: URL) -> [[Builder]]? {
        var builders = [Builder]()

        let url = url.standardizedFileURL.resolvingSymlinksInPath()
        totalFileCount = determineFileCount(from: url)
        progressSubject.onNext(0)

        builders.append(contentsOf: extractBuilders(from: url))

        // Extract non-core components and apply to corresponding builders
        extractComponents(from: url, applyTo: builders)
        extractPluginPoints(from: url)
        extractPluginFactories(from: url)

        let hierarchicalBuilders = createHierarchy(from: builders)

        let levelOrderBuilders = createLevelOrderBuilders(from: hierarchicalBuilders)

        return levelOrderBuilders
    }

    // MARK: - Private
    private func extractBuilders(from path: URL) -> [Builder] {
        var builders = [Builder]()

        // Actually begin parsing, updating the progress value incrementally
        progressSubject.onNext(0)

        if let enumerator = FileManager.default.enumerator(at: path, includingPropertiesForKeys: resourceKeys, options: [.skipsHiddenFiles], errorHandler: { (url, error) -> Bool in
            print("directoryEnumerator error ast \(url): ", error)

            return true
        }) {
            for case let fileURL as URL in enumerator {
                guard fileURL.path.contains("Builder.swift") else { continue }

                if let fileSubstring = fileURL.absoluteString.split(separator: "/").last {
                    progressFileSubject.onNext(String(fileSubstring))
                }

                if fileURL.path.contains("Builder.swift") {

                    var parsedBuilders: [ Builder ]?
                    do {
                        parsedBuilders = try self.builderParser.parse(fileURL: fileURL)
                    } catch {
                        print(error)
                    }

                    if let parsedBuilders = parsedBuilders {
                        builders.append(contentsOf: parsedBuilders)
                    }
                }
                incrementFileCount()
            }
        }

        return builders
    }

    private func extractComponents(from path: URL, applyTo builders: [Builder]) {

        if let enumerator = FileManager.default.enumerator(at: path, includingPropertiesForKeys: resourceKeys, options: [.skipsHiddenFiles], errorHandler: { (url, error) -> Bool in
            print("directoryEnumerator error ast \(url): ", error)

            return true
        }) {
            for case let fileURL as URL in enumerator {
                guard fileURL.path.contains("NonCoreComponent.swift") else { continue }

                if let fileSubstring = fileURL.absoluteString.split(separator: "/").last {
                    progressFileSubject.onNext(String(fileSubstring))
                }

                if fileURL.path.contains("NonCoreComponent.swift") {
                    do {
                        try self.componentParser.parse(fileURL: fileURL, applyTo: builders)
                    } catch {
                        print(error)
                    }
                }
                incrementFileCount()
            }
        }
    }

    private func extractPluginPoints(from path: URL) {
        if let enumerator = FileManager.default.enumerator(at: path, includingPropertiesForKeys: resourceKeys, options: [.skipsHiddenFiles], errorHandler: { (url, error) -> Bool in
            print("directoryEnumerator error ast \(url): ", error)

            return true
        }) {
            for case let fileURL as URL in enumerator {
                guard fileURL.path.contains("PluginPoint.swift") else { continue }

                if let fileSubstring = fileURL.absoluteString.split(separator: "/").last {
                    progressFileSubject.onNext(String(fileSubstring))
                }

                if fileURL.path.contains("PluginPoint") {
                    do {
                        try self.pluginPointParser.parse(fileURL: fileURL)
                    } catch {
                        print(error)
                    }
                }
                incrementFileCount()
            }
        }
    }

    private func extractPluginFactories(from path: URL) {
        if let enumerator = FileManager.default.enumerator(at: path, includingPropertiesForKeys: resourceKeys, options: [.skipsHiddenFiles], errorHandler: { (url, error) -> Bool in
            print("directoryEnumerator error ast \(url): ", error)

            return true
        }) {
            for case let fileURL as URL in enumerator {
                guard fileURL.path.contains("PluginFactory") else { continue }

                if let fileSubstring = fileURL.absoluteString.split(separator: "/").last {
                    progressFileSubject.onNext(String(fileSubstring))
                }

                if fileURL.path.contains("PluginFactory") {
                    print(fileURL)
//                    do {
//                        try self.componentParser.parse(fileURL: fileURL, applyTo: builders)
//                    } catch {
//                        print(error)
//                    }
                }
                incrementFileCount()
            }
        }
    }

    private func determineFileCount(from path: URL) -> Int {

        var totalFileCount = 0

        // First enumeration to establish how many files there are
        if let countEnumerator = FileManager.default.enumerator(at: path, includingPropertiesForKeys: resourceKeys, options: [.skipsHiddenFiles], errorHandler: { (url, error) -> Bool in return true }) {
            for case let fileURL as URL in countEnumerator {
                if fileURL.path.contains("Builder.swift") ||
                    fileURL.path.contains("Component.swift") ||
                    fileURL.path.contains("PluginPoint") ||
                    fileURL.path.contains("PluginFactory") {
                    totalFileCount = totalFileCount + 1
                }
            }
        }

        return totalFileCount
    }

    private func incrementFileCount() {
        DispatchQueue.main.async {
            self.currentFileIndex = self.currentFileIndex + 1
            self.progressSubject.onNext(Double(self.currentFileIndex) / Double(self.totalFileCount))
        }
    }

    private func createLevelOrderBuilders(from builders: [Builder]) -> [[Builder]]? {

        var nodeCountLookup = [ String: Int ]()
        var nodeLookup = [ String: Builder ]()

        for node in builders {
            nodeCountLookup[node.name] = node.totalNodesBeneath()
            nodeLookup[node.name] = node
        }

//        let sorted = nodeCountLookup.sorted { $0.value > $1.value }

        let rootBuilder = nodeLookup["RootBuilder"]
        return rootBuilder?.nodesAtEachDepth()

//        // TODO: Reinstate
//        if let rootName = sorted.first?.key,
//           let builder = nodeLookup[rootName] {
//            return builder.nodesAtEachDepth()
//        }
//
//        return nil
    }

    private func createHierarchy(from builders: [Builder]) -> [Builder] {

        // ON^2, oh well
        for builder in builders {
            for f in builder.childRIBs {

                // Check the corresponding childBuilder doesn't already exist
                let existingBuilders = builder.childBuilders.filter { (builder: Builder) -> Bool in
                    return builder.name == f.postfixExpression.textDescription
                }
                if existingBuilders.count > 0 {
                    continue
                }

                let matchingBuilders = builders.filter { (builder: Builder) -> Bool in
                    return builder.name == f.postfixExpression.textDescription
                }
                if matchingBuilders.count == 1,
                    let matchingBuilder = matchingBuilders.first {
                    builder.childBuilders.append(matchingBuilder)
                    matchingBuilder.parentRIB = builder
                }
            }
        }

        return builders
    }
}
