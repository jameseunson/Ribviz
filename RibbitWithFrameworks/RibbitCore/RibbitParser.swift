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

public class RibbitParser {

    let resourceKeys : [URLResourceKey] = [.creationDateKey, .isDirectoryKey]
    let parser = BuilderParser()

    private let progressSubject = PublishSubject<Double>()
    private let progressFileSubject = PublishSubject<String>()

    let progress: Observable<Double>
    let progressFile: Observable<String>

    public init() {
        progress = progressSubject.asObservable()
        progressFile = progressFileSubject.asObservable()
    }

    public func retrieveBuilders(url: URL) -> [[Builder]]? {
        var builders = [Builder]()

        builders.append(contentsOf: extractBuilders(from: url.standardizedFileURL.resolvingSymlinksInPath()))
        let hierarchicalBuilders = createHierarchy(from: builders)

        let levelOrderBuilders = createLevelOrderBuilders(from: hierarchicalBuilders)

        return levelOrderBuilders
    }

    private func extractBuilders(from path: URL) -> [Builder] {
        var builders = [Builder]()
        do {
            var totalfileCount = 0
            var currentFileIndex = 0

            // First enumeration to establish how many files there are
            if let countEnumerator = FileManager.default.enumerator(at: path, includingPropertiesForKeys: resourceKeys, options: [.skipsHiddenFiles], errorHandler: { (url, error) -> Bool in return true }) {
                for case let fileURL as URL in countEnumerator {
                    if fileURL.path.contains("Builder.swift") {
                        totalfileCount = totalfileCount + 1
                    }
                }
            }

            // Actually begin parsing, updating the progress value incrementally
            progressSubject.onNext(0)

            if let enumerator = FileManager.default.enumerator(at: path, includingPropertiesForKeys: resourceKeys, options: [.skipsHiddenFiles], errorHandler: { (url, error) -> Bool in
                print("directoryEnumerator error ast \(url): ", error)

                return true
            }) {
                for case let fileURL as URL in enumerator {
                    if fileURL.path.contains("Builder.swift") {

                        if let fileSubstring = fileURL.absoluteString.split(separator: "/").last {
                            progressFileSubject.onNext(String(fileSubstring))
                        }

                        let parsedBuilders = try parser.parse(fileURL: fileURL)
                        builders.append(contentsOf: parsedBuilders)

                        currentFileIndex = currentFileIndex + 1
                        let progress = Double(currentFileIndex) / Double(totalfileCount)

                        progressSubject.onNext(progress)
                    }
                }
            }

        } catch {
            print(error)
        }
        return builders
    }

    private func createLevelOrderBuilders(from builders: [Builder]) -> [[Builder]]? {

        var nodeCountLookup = [ String: Int ]()
        var nodeLookup = [ String: Builder ]()

        for node in builders {
            nodeCountLookup[node.name] = node.totalNodesBeneath()
            nodeLookup[node.name] = node
        }

        let sorted = nodeCountLookup.sorted { $0.value > $1.value }
        if let rootName = sorted.first?.key,
           let builder = nodeLookup[rootName] {
            return builder.nodesAtEachDepth()
        }

        return nil
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
