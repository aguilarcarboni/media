//
//  LibraryView.swift
//  media
//
//  Created by Andrés on 28/6/2025.
//

import SwiftUI
import SwiftData

struct LibraryView: View {
    @StateObject private var cloudKitManager = CloudKitManager.shared
    @State private var selectedSidebarItem: SidebarItem? = nil

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedSidebarItem) {
                Section {
                    ForEach(SidebarItem.allCases) { item in
                        Label(item.rawValue, systemImage: item.systemImage)
                            .tag(item)
                    }
                }

                Section("Sync Status") {
                    HStack {
                        Image(systemName: cloudKitManager.isSignedInToiCloud ? "icloud.fill" : "icloud.slash")
                            .foregroundColor(cloudKitManager.isSignedInToiCloud ? .blue : .gray)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(cloudKitManager.isSignedInToiCloud ? "iCloud Connected" : "iCloud Disconnected")
                                .font(.caption)
                                .fontWeight(.medium)
                            Text(cloudKitManager.syncStatus.description)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if case .syncing = cloudKitManager.syncStatus {
                            ProgressView().scaleEffect(0.7)
                        }
                    }
                    .onTapGesture {
                        Task { await cloudKitManager.forceSyncNow() }
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Library")
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 250)
        } detail: {
            switch selectedSidebarItem {
                case .movies:
                    MoviesView()
                case .tvShows:
                    TVGeneralView()
                case .games:
                    GamesView()
                case .books:
                    BooksView()
                case .comics:
                    ComicsView()
                case .none:
                    VStack(spacing: 16) {
                        Image(systemName: "sidebar.left")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("Select a category from the sidebar")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .cloudKitStatusAlert()
        .task {
            await cloudKitManager.checkCloudKitStatus()
        }
    }
}

enum SidebarItem: String, CaseIterable, Identifiable {
    case movies = "Movies"
    case tvShows = "TV Shows"
    case games = "Games"
    case books = "Books"
    case comics = "Comics"
    
    var id: String { self.rawValue }
    
    var systemImage: String {
        switch self {
        case .movies:
            return "film"
        case .tvShows:
            return "tv"
        case .games:
            return "gamecontroller"
        case .books:
            return "book.closed"
        case .comics:
            return "book"
        }
    }
}
