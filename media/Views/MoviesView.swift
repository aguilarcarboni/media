//
//  MoviesView.swift
//  media
//
//  Created by Andrés on 28/6/2025.
//

import SwiftUI
import SwiftData

struct MoviesView: View {
    let movies: [Movie]
    @Binding var selectedMovie: Movie?
    @Binding var showingMovieDetail: Bool
    @Binding var showingCreateSheet: Bool
    @Binding var showingImportSheet: Bool
    
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
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Movies (\(movies.count))")
        .sheet(isPresented: $showingCreateSheet) {
            CreateMovieView()
        }
        .sheet(isPresented: $showingImportSheet) {
            MoviesCSVImportView()
        }
        .sheet(isPresented: $showingMovieDetail) {
            if let selectedMovie = selectedMovie {
                NavigationStack {
                    MovieView(movie: selectedMovie)
                        .navigationTitle(selectedMovie.title)
                }
            }
        }
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

struct MovieRowView: View {
    let movie: Movie
    
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