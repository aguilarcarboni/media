//
//  MovieView.swift
//  media
//
//  Created by Andrés on 28/6/2025.
//

import SwiftUI
import SwiftData

struct MovieView: View {
    @Bindable var movie: Movie
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header with backdrop
                ZStack(alignment: .bottomLeading) {
                    // Backdrop image
                    AsyncImage(url: movie.backdropURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(.secondary.opacity(0.3))
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.secondary)
                            }
                    }
                    .frame(height: 200)
                    .clipped()
                    
                    // Gradient overlay
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    // Title overlay
                    VStack(alignment: .leading, spacing: 4) {
                        Text(movie.title)
                            .font(.largeTitle)
                            .bold()
                            .foregroundStyle(.white)
                            .shadow(color: .black, radius: 2)
                        
                        HStack {
                            if let year = movie.year {
                                Text("\(year)")
                                    .font(.title3)
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                            
                            if let rating = movie.displayRating {
                                Text("⭐ \(rating, specifier: "%.1f")")
                                    .font(.title3)
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                        }
                    }
                    .padding()
                }
                .cornerRadius(12)
                
                HStack(alignment: .top, spacing: 16) {
                    // Poster
                    AsyncImage(url: movie.posterURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Rectangle()
                            .fill(.secondary.opacity(0.3))
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.secondary)
                            }
                    }
                    .frame(width: 120, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    // Movie details
                    VStack(alignment: .leading, spacing: 12) {
                        // Watched status
                        HStack {
                            Image(systemName: movie.watched ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(movie.watched ? .green : .secondary)
                                .font(.title2)
                            
                            Text(movie.watched ? "Watched" : "Not Watched")
                                .font(.headline)
                                .foregroundStyle(movie.watched ? .green : .secondary)
                        }
                        
                        // Quick details
                        VStack(alignment: .leading, spacing: 6) {
                            if let runtime = movie.runtime {
                                Label("\(runtime) minutes", systemImage: "clock")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            if !movie.genreList.isEmpty {
                                Label(movie.genreList.joined(separator: ", "), systemImage: "tag")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            if let releaseDate = movie.releaseDateFormatted {
                                Label {
                                    Text(releaseDate, format: .dateTime.day().month().year())
                                } icon: {
                                    Image(systemName: "calendar")
                                }
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
                
                // Overview
                if let overview = movie.overview, !overview.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Overview")
                            .font(.headline)
                        Text(overview)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(8)
                }
                
                // Cast and Crew
                if !movie.castList.isEmpty || !movie.directorList.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Cast & Crew")
                            .font(.headline)
                        
                        if !movie.directorList.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Directors")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(movie.directorList.joined(separator: ", "))
                                    .font(.body)
                            }
                        }
                        
                        if !movie.castList.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Cast")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(movie.castList.joined(separator: ", "))
                                    .font(.body)
                            }
                        }
                    }
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(8)
                }
                
                // Additional Details
                VStack(alignment: .leading, spacing: 8) {
                    Text("Details")
                        .font(.headline)
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text("Added:")
                            Spacer()
                            Text(movie.created, format: .dateTime.day().month().year())
                        }
                        
                        if movie.updated != movie.created {
                            HStack {
                                Text("Updated:")
                                Spacer()
                                Text(movie.updated, format: .dateTime.day().month().year())
                            }
                        }
                        
                        if let tmdbId = movie.tmdbId {
                            HStack {
                                Text("TMDB ID:")
                                Spacer()
                                Text(tmdbId)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        if movie.rating != nil && movie.tmdbRating != nil {
                            HStack {
                                Text("Your Rating:")
                                Spacer()
                                Text("⭐ \(movie.rating!, specifier: "%.1f")")
                            }
                            
                            HStack {
                                Text("TMDB Rating:")
                                Spacer()
                                Text("⭐ \(movie.tmdbRating!, specifier: "%.1f")")
                            }
                        }
                    }
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(8)
                
                Spacer()
            }
            .padding()
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if let tmdbId = movie.tmdbId {
                    Button("Refresh from TMDB") {
                        refreshFromTMDB()
                    }
                }
                
                Button(movie.watched ? "Mark Unwatched" : "Mark Watched") {
                    if movie.watched {
                        movie.markAsUnwatched()
                    } else {
                        movie.markAsWatched()
                    }
                }
            }
        }
    }
    
    private func refreshFromTMDB() {
        guard let tmdbIdString = movie.tmdbId,
              let tmdbId = Int(tmdbIdString) else { return }
        
        Task {
            do {
                let tmdbMovie = try await TMDBAPIManager.shared.getMovie(id: tmdbId)
                await MainActor.run {
                    movie.updateFromTMDB(tmdbMovie)
                }
            } catch {
                print("Failed to refresh from TMDB: \(error)")
            }
        }
    }
} 

