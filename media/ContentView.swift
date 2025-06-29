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
    @StateObject private var cloudKitManager = CloudKitManager.shared
    @State private var showingCreateSheet = false
    @State private var showingImportSheet = false
    @State private var selectedMovie: Movie?
    @State private var showingMovieDetail = false
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
                        showingCreateSheet: $showingCreateSheet,
                        showingImportSheet: $showingImportSheet
                    )
                case .tvShows:
                    ContentUnavailableView {
                        Label("No TV Shows", systemImage: "tray.fill")
                    } description: {
                        Text("TV Shows feature is coming soon!")
                    }
                case .comics:
                    ContentUnavailableView {
                        Label("No Comics", systemImage: "tray.fill")
                    } description: {
                        Text("Comics feature is coming soon!")
                    }
                case .games:
                    ContentUnavailableView {
                        Label("No Games", systemImage: "tray.fill")
                    } description: {
                        Text("Games feature is coming soon!")
                    }
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
        .sheet(isPresented: $showingCreateSheet) {
            CreateMovieView()
        }
        .sheet(isPresented: $showingImportSheet) {
            CSVImportView()
        }
        .sheet(isPresented: $showingMovieDetail) {
            if let selectedMovie = selectedMovie {
                NavigationStack {
                    MovieView(movie: selectedMovie)
                        .navigationTitle(selectedMovie.title)
                }
            }
        }
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
        }
    }
}
