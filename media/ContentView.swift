//
//  ContentView.swift
//  media
//
//  Created by Andrés on 28/6/2025.
//

import SwiftUI

struct ContentView: View {
    enum Tabs: Hashable {
        case search
        case library
        case explore
    }

    @State private var selectedTab: Tabs = .library

    var body: some View {
        TabView(selection: $selectedTab) {
            // Library tab
            Tab("Library", systemImage: "books.vertical", value: Tabs.library) {
                LibraryView()
            }

            Tab("Explore", systemImage: "play", value: Tabs.explore) {
                ContentUnavailableView("Explore", systemImage: "play", description: Text("Explore coming soon..."))
            }

            // Search tab — note the role
            Tab(value: Tabs.search, role: .search) {
                SearchView()
            }
        }
    }
}
