//  TVGeneralView.swift
//  media
//
//  Created by AI on 08/07/2025.
//
//  High-level entry point for TV content, mirroring ComicsView (Shows & Episodes).

import SwiftUI

struct TVGeneralView: View {
    enum Section: Hashable {
        case shows
        case episodes

        var title: String {
            switch self {
            case .shows: "Shows"
            case .episodes: "Episodes"
            }
        }
        var systemImage: String {
            switch self {
            case .shows: "tv"
            case .episodes: "rectangle.stack"
            }
        }
    }

    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            List {
                NavigationLink(value: Section.shows) {
                    Label(Section.shows.title, systemImage: Section.shows.systemImage)
                }
                NavigationLink(value: Section.episodes) {
                    Label(Section.episodes.title, systemImage: Section.episodes.systemImage)
                }
            }
            .navigationTitle("TV")
            .navigationDestination(for: Section.self) { section in
                switch section {
                case .shows: TVShowsView()
                case .episodes: TVEpisodesView()
                }
            }
        }
    }
}

#Preview {
    TVGeneralView()
} 