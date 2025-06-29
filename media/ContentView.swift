//
//  ContentView.swift
//  media
//
//  Created by Andrés on 28/6/2025.
//

import SwiftUI
import SwiftData

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

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var movies: [Movie]
    @StateObject private var cloudKitManager = CloudKitManager.shared
    @State private var showingCreateSheet = false
    @State private var showingImportSheet = false
    @State private var selectedMovie: Movie?
    @State private var showingMovieDetail = false
    @State private var selectedSidebarItem: SidebarItem = .movies

    var body: some View {
        NavigationSplitView {
            // Sidebar - selectable list of media types
            List {
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
            // Main content - shows content based on sidebar selection
            Group {
                switch selectedSidebarItem {
                case .movies:
                    MoviesContentView(
                        movies: movies,
                        selectedMovie: $selectedMovie,
                        showingMovieDetail: $showingMovieDetail,
                        showingCreateSheet: $showingCreateSheet,
                        showingImportSheet: $showingImportSheet,
                        deleteMovies: deleteMovies
                    )
                case .tvShows:
                    UnavailableContentView(
                        title: "TV Shows",
                        systemImage: "tv",
                        description: "TV Shows feature is coming soon!"
                    )
                
                case .comics:
                    UnavailableContentView(
                        title: "Comics",
                        systemImage: "book",
                        description: "Comics feature is coming soon!"
                    )
                case .games:
                    UnavailableContentView(
                        title: "Games",
                        systemImage: "gamecontroller",
                        description: "Games feature is coming soon!"
                    )
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateMovieView()
            }
            .sheet(isPresented: $showingImportSheet) {
                CSVImportView()
            }
            .sheet(isPresented: $showingMovieDetail) {
                if let selectedMovie = selectedMovie {
                    MovieDetailSheet(movie: selectedMovie) {
                        showingMovieDetail = false
                    }
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .cloudKitStatusAlert()
        .task {
            await cloudKitManager.checkCloudKitStatus()
        }
    }

    private func deleteMovies(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(movies[index])
            }
        }
    }
}

struct MoviesContentView: View {
    let movies: [Movie]
    @Binding var selectedMovie: Movie?
    @Binding var showingMovieDetail: Bool
    @Binding var showingCreateSheet: Bool
    @Binding var showingImportSheet: Bool
    let deleteMovies: (IndexSet) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            if movies.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "film")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    
                    VStack(spacing: 8) {
                        Text("No Movies Yet")
                            .font(.title2)
                            .bold()
                        
                        Text("Add your first movie to get started")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button(action: { showingCreateSheet = true }) {
                        Label("Add Movie", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(movies) { movie in
                        Button(action: {
                            selectedMovie = movie
                            showingMovieDetail = true
                        }) {
                            MovieRowView(movie: movie)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: deleteMovies)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Movies (\(movies.count))")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { showingImportSheet = true }) {
                    Label("Import CSV", systemImage: "doc.text")
                }
                .help("Import items from CSV file")
                
                Button(action: { showingCreateSheet = true }) {
                    Label("Add Item", systemImage: "plus")
                }
                .help("Add new movie")
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }
}

struct UnavailableContentView: View {
    let title: String
    let systemImage: String
    let description: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .bold()
                
                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(title)
    }
}

struct MovieDetailSheet: View {
    @Bindable var movie: Movie
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            MovieView(movie: movie)
                .navigationTitle(movie.title)
                .toolbar {
                    ToolbarItem() {
                        Button("Done") {
                            onDismiss()
                        }
                    }
                }
        }
    }
}

struct MovieRowView: View {
    let movie: Movie
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(movie.title)
                    .font(.headline)
                    .strikethrough(movie.watched)
                
                HStack {
                    if let year = movie.year {
                        Text("\(year)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let genres = movie.genres {
                        Text("• \(genres)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let rating = movie.displayRating {
                        Text("• ⭐ \(rating, specifier: "%.1f")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if movie.watched {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Movie.self, inMemory: true)
}
