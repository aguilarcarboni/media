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

        var title: String {
            switch self {
            case .volumes: "Volumes"
            case .issues: "Issues"
            }
        }
        var systemImage: String {
            switch self {
            case .volumes: "books.vertical"
            case .issues: "book"
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
            }
            .navigationTitle("Comics")
            .navigationDestination(for: Section.self) { section in
                switch section {
                case .volumes: VolumesView()
                case .issues: IssuesView()
                }
            }
        }
    }
} 