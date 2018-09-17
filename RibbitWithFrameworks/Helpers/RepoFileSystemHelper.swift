//
//  RepoFileSystemHelper.swift
//  RibbitWithFrameworks
//
//  Created by James Eunson on 9/17/18.
//  Copyright © 2018 Uber. All rights reserved.
//

import Foundation
import Cocoa
import RxSwift

enum RepoFileSystemHelperError: Error {
    case genericError
    case unsupportedFolder
    case couldNotUsedSecurityScopedURL
}

class RepoFileSystemHelper {

    func selectRepoDirectory() -> Observable<URL?> {

        let urlSubject = PublishSubject<URL?>()

        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = false

        openPanel.begin
            { (result) -> Void in
                guard let url = openPanel.url,
                    let path = self.pathToBookmarks() else {
                    urlSubject.onError(RepoFileSystemHelperError.genericError)
                    return
                }

                // Could be a more detailed check, but this works
                guard url.absoluteString.contains("apps") else {
//                    NSAlert.displayError(messageText: "Unsupported project folder", informativeText: "Specified directory does not appear to be for a supported app. Please select a directory for a monorepo app, such as 'iphone-helix' or 'carbon'.")
                    urlSubject.onError(RepoFileSystemHelperError.unsupportedFolder)
                    return
                }

                do {
                    let data = try url.bookmarkData(options: NSURL.BookmarkCreationOptions.withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)

                    NSKeyedArchiver.archiveRootObject([ path: data ], toFile: path)
                    urlSubject.onNext(url)

                } catch {
                    urlSubject.onError(RepoFileSystemHelperError.genericError)
                    return
                }
        }

        return urlSubject.asObservable()
    }

    func loadURLBookmark() -> URL? {
        var isStale = false

        guard let path = self.pathToBookmarks(),
            let bookmark = NSKeyedUnarchiver.unarchiveObject(withFile: path) as? [String: Data],
            let bookmarkKey = bookmark.keys.first,
            let bookmarkData = bookmark[bookmarkKey] else {
            return nil
        }

        do {
            if let restoredUrl = try URL(resolvingBookmarkData: bookmarkData, options: NSURL.BookmarkResolutionOptions.withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale),
                restoredUrl.startAccessingSecurityScopedResource() {

                return restoredUrl
            }
        } catch {}

        return nil
    }

    private func pathToBookmarks() -> String? {
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return url.appendingPathComponent("Bookmarks.dict").path
    }
}
