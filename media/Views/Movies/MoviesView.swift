//
//  MoviesView.swift
//  media
//
//  Created by Andrés on 28/6/2025.
//

import SwiftUI
import SwiftData

struct MoviesView: View {
    
    @Query private var movies: [Movie]
    @State private var selectedMovie: Movie?
    @State private var showingCreateSheet = false
    @State private var searchQuery = ""

    // Filtering
    enum FilterOption: String, CaseIterable, Identifiable {
        case all = "All"
        case watched = "Watched"
        case unwatched = "Unwatched"

        var id: Self { self }
    }

    @State private var filterOption: FilterOption = .all

    private var filteredMovies: [Movie] {
        movies
            .filter { movie in
                switch filterOption {
                case .all:
                    return true
                case .watched:
                    return movie.watched
                case .unwatched:
                    return !movie.watched
                }
            }
            .filter { movie in
                searchQuery.isEmpty || movie.title.localizedCaseInsensitiveContains(searchQuery)
            }
    }

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
                    ForEach(filteredMovies) { movie in
                        MovieRowView(movie: movie)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedMovie = movie }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Movies")
        .sheet(item: $selectedMovie) { movie in
            NavigationStack {
                MovieView(movie: movie)
                    .navigationTitle(movie.title)
            }
        }
        .searchable(text: $searchQuery)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Picker("Filter", selection: $filterOption) {
                        ForEach(FilterOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
    }
}

struct MovieRowView: View {
    @Bindable var movie: Movie
    
    var body: some View {
        HStack {
            AsyncImage(url: movie.thumbnailURL) { img in
                img.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(.secondary.opacity(0.2))
                    .overlay { Image(systemName: "photo") }
            }
            .frame(width: 40, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading, spacing: 4) {
                Text(movie.title)
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 4) {
                    if let directors = movie.directors {
                        Text(directors)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let year = movie.year {
                        Text(String(year))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                if movie.watched {
                    movie.markAsUnwatched()
                } else {
                    movie.markAsWatched()
                }
            }) {
                Image(systemName: movie.watched ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(movie.watched ? .green : .secondary)
            }
            .buttonStyle(.borderless)
        }
    }
}
