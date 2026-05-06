//
//  PathSegment.swift
//  Explorer
//

import Foundation

struct PathSegment: Identifiable, Hashable {
    let id: Int
    let title: String
    let url: URL

    static func segments(for url: URL) -> [PathSegment] {
        let components = url.pathComponents
        guard !components.isEmpty else { return [] }

        var accumulated = URL(filePath: "/", directoryHint: .isDirectory)
        var result: [PathSegment] = []

        for (index, component) in components.enumerated() {
            if component == "/" {
                result.append(PathSegment(id: index, title: "Macintosh HD", url: accumulated))
            } else {
                accumulated.append(component: component, directoryHint: .isDirectory)
                result.append(PathSegment(id: index, title: component, url: accumulated))
            }
        }
        return result
    }
}
