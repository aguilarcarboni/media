//
//  ComicsView.swift
//  media
//
//  Created by AI on 07/07/2025.
//
//  Top-level view for Comics library showing Volumes or Issues list.
//

import SwiftUI

struct ComicsView: View {
    // Sections pushable via NavigationStack
    enum Section: Hashable {
        case volumes
        case issues
        case readingLists

        var title: String {
            switch self {
            case .volumes: "Volumes"
            case .issues: "Issues"
            case .readingLists: "Reading Lists"
            }
        }
        var systemImage: String {
            switch self {
            case .volumes: "books.vertical"
            case .issues: "book"
            case .readingLists: "list.bullet.rectangle"
            }
        }
    }

    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            List {
                NavigationLink(value: Section.volumes) {
                    Label(Section.volumes.title, systemImage: Section.volumes.systemImage)
                }
                NavigationLink(value: Section.issues) {
                    Label(Section.issues.title, systemImage: Section.issues.systemImage)
                }
                NavigationLink(value: Section.readingLists) {
                    Label(Section.readingLists.title, systemImage: Section.readingLists.systemImage)
                }
            }
            .navigationTitle("Comics")
            .navigationDestination(for: Section.self) { section in
                switch section {
                case .volumes: VolumesView()
                case .issues: IssuesView()
                case .readingLists: ReadingListsView()
                }
            }
        }
    }
} 