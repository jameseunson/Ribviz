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

                guard result != NSApplication.ModalResponse.cancel else {
                    return
                }

                guard let url = openPanel.url,
                    let path = self.pathToBookmarks() else {
                    urlSubject.onError(RepoFileSystemHelperError.genericError)
                    return
                }

                // Could be a more detailed check, but this works
                guard url.absoluteString.contains("apps") else {
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

    func removeBookmark() -> Bool {
        guard let path = self.pathToBookmarks() else {
            return false
        }
        do {
            try FileManager.default.removeItem(at: URL(fileURLWithPath: path))
        } catch {
            return false
        }
        return true
    }

    private func pathToBookmarks() -> String? {
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return url.appendingPathComponent("Bookmarks.dict").path
    }
}
