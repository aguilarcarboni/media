//
//  ContentView.swift
//  media
//
//  Created by Andrés on 28/6/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query private var movies: [Movie]
    @Query private var tvShows: [TVShow]
    @Query private var games: [Game]
    @Query private var books: [Book]
    @StateObject private var cloudKitManager = CloudKitManager.shared
    
    // Movie state
    @State private var showingCreateMovieSheet = false
    @State private var showingImportMovieSheet = false
    @State private var selectedMovie: Movie?
    @State private var showingMovieDetail = false
    
    // TV Show state
    @State private var showingCreateTVShowSheet = false
    @State private var showingImportTVShowSheet = false
    @State private var selectedTVShow: TVShow?
    @State private var showingTVShowDetail = false
    
    // Game state
    @State private var showingCreateGameSheet = false
    @State private var selectedGame: Game?
    @State private var showingGameDetail = false
    
    // Book state
    @State private var showingCreateBookSheet = false
    @State private var selectedBook: Book?
    @State private var showingBookDetail = false
    
    @State private var selectedSidebarItem: SidebarItem? = .movies

    var body: some View {
        NavigationSplitView {
            // Sidebar - selectable list of media types
            List(selection: $selectedSidebarItem) {
                Section {
                    ForEach(SidebarItem.allCases, id: \.self) { item in
                        NavigationLink(value: item) {
                            Label(item.rawValue, systemImage: item.systemImage)
                        }
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
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if case .syncing = cloudKitManager.syncStatus {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                    }
                    .onTapGesture {
                        Task {
                            await cloudKitManager.forceSyncNow()
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Media")
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 250)

        } detail: {
            // Detail view
            Group {
                switch selectedSidebarItem {
                case .movies:
                    MoviesView(
                        movies: movies,
                        selectedMovie: $selectedMovie,
                        showingMovieDetail: $showingMovieDetail,
                        showingCreateSheet: $showingCreateMovieSheet,
                        showingImportSheet: $showingImportMovieSheet
                    )
                case .tvShows:
                    TVShowsView(
                        tvShows: tvShows,
                        selectedTVShow: $selectedTVShow,
                        showingTVShowDetail: $showingTVShowDetail,
                        showingCreateSheet: $showingCreateTVShowSheet,
                        showingImportSheet: $showingImportTVShowSheet
                    )
                case .comics:
                    ContentUnavailableView {
                        Label("No Comics", systemImage: "tray.fill")
                    } description: {
                        Text("Comics feature is coming soon!")
                    }
                case .games:
                    GamesView(
                        games: games,
                        selectedGame: $selectedGame,
                        showingGameDetail: $showingGameDetail,
                        showingCreateSheet: $showingCreateGameSheet
                    )
                case .books:
                    BooksView(
                        books: books,
                        selectedBook: $selectedBook,
                        showingBookDetail: $showingBookDetail,
                        showingCreateSheet: $showingCreateBookSheet
                    )
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
    case comics = "Comics"
    case games = "Games"
    case books = "Books"
    
    var id: String { self.rawValue }
    
    var systemImage: String {
        switch self {
        case .movies:
            return "film"
        case .tvShows:
            return "tv"
        case .comics:
            return "book"
        case .games:
            return "gamecontroller"
        case .books:
            return "book.closed"
        }
    }
}
