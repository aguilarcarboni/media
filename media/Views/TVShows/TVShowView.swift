//
//  TVShowView.swift
//  media
//
//  Created by Andrés on 28/6/2025.
//

import SwiftUI
import SwiftData

struct TVShowView: View {
    @Bindable var tvShow: TVShow
    var isPreview: Bool = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                HStack(alignment: .top, spacing: 16) {
                    // Poster
                    AsyncImage(url: tvShow.posterURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Rectangle()
                            .fill(.secondary.opacity(0.3))
                            .overlay {
                                Image(systemName: "tv")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.secondary)
                            }
                    }
                    .frame(width: 120, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    // TV Show details
                    VStack(alignment: .leading, spacing: 12) {
                        // Watched status
                        HStack {
                            Image(systemName: tvShow.watched ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(tvShow.watched ? .green : .secondary)
                                .font(.title2)
                            
                            Text(tvShow.watched ? "Watched" : "Not Watched")
                                .font(.headline)
                                .foregroundStyle(tvShow.watched ? .green : .secondary)
                        }
                        
                        // Quick details
                        VStack(alignment: .leading, spacing: 6) {
                            if let numberOfSeasons = tvShow.numberOfSeasons {
                                Label("\(numberOfSeasons) season\(numberOfSeasons == 1 ? "" : "s")", systemImage: "tv")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            if let numberOfEpisodes = tvShow.numberOfEpisodes {
                                Label("\(numberOfEpisodes) episodes", systemImage: "rectangle.grid.3x2")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            if !tvShow.genreList.isEmpty {
                                Label(tvShow.genreList.joined(separator: ", "), systemImage: "tag")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            if let airDate = tvShow.airDateFormatted {
                                Label {
                                    Text(airDate, format: .dateTime.day().month().year())
                                } icon: {
                                    Image(systemName: "calendar")
                                }
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }
                            
                            if let status = tvShow.status {
                                Label(status, systemImage: "info.circle")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
                
                // Overview
                if let overview = tvShow.overview, !overview.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Overview")
                            .font(.headline)
                        Text(overview)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                // Seasons
                if !tvShow.seasonList.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Seasons")
                            .font(.headline)
                        
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 100))
                        ], spacing: 8) {
                            ForEach(tvShow.seasonList, id: \.self) { season in
                                Text(season)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.regularMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                // Cast and Crew
                if !tvShow.castList.isEmpty || !tvShow.creatorList.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Cast & Crew")
                            .font(.headline)
                        
                        if !tvShow.creatorList.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Creators")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(tvShow.creatorList.joined(separator: ", "))
                                    .font(.body)
                            }
                        }
                        
                        if !tvShow.castList.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Cast")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(tvShow.castList.joined(separator: ", "))
                                    .font(.body)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8)) 
                }
                
                // Additional Details
                VStack(alignment: .leading, spacing: 8) {
                    Text("Details")
                        .font(.headline)
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text("Added:")
                            Spacer()
                            Text(tvShow.created, format: .dateTime.day().month().year())
                        }
                        
                        if tvShow.updated != tvShow.created {
                            HStack {
                                Text("Updated:")
                                Spacer()
                                Text(tvShow.updated, format: .dateTime.day().month().year())
                            }
                        }
                        
                        if let tmdbId = tvShow.tmdbId {
                            HStack {
                                Text("TMDB ID:")
                                Spacer()
                                Text(tmdbId)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        if let userRating = tvShow.rating {
                            HStack {
                                Text("Your Rating:")
                                Spacer()
                                Text("⭐ \(userRating, specifier: "%.1f")")
                            }
                        }

                        if let apiRating = tvShow.tmdbRating {
                            HStack {
                                Text("TMDB Rating:")
                                Spacer()
                                Text("⭐ \(apiRating, specifier: "%.1f")")
                            }
                        }

                        if let seasons = tvShow.numberOfSeasons {
                            HStack {
                                Text("Seasons:")
                                Spacer()
                                Text("\(seasons)")
                            }
                        }

                        if let episodes = tvShow.numberOfEpisodes {
                            HStack {
                                Text("Episodes:")
                                Spacer()
                                Text("\(episodes)")
                            }
                        }
                    }
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Backdrop
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: tvShow.backdropURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(.secondary.opacity(0.3))
                            .overlay {
                                Image(systemName: "tv")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.secondary)
                            }
                    }
                    .frame(height: 200)
                    .clipped()
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding()
        }
        .toolbar {
            if isPreview {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        modelContext.insert(tvShow)
                        dismiss()
                    }
                }
            } else {
                ToolbarItem() {
                    Button {
                        if tvShow.watched { tvShow.markAsUnwatched() } else { tvShow.markAsWatched() }
                    } label: {
                        Image(systemName: tvShow.watched ? "checkmark.circle.fill" : "circle")
                    }
                }
                ToolbarItem() {
                    Menu {
                        if tvShow.tmdbId != nil {
                            Button("Refresh from TMDB") { refreshFromTMDB() }
                        }
                    } label: { Image(systemName: "ellipsis") }
                }
            }
        }
    }
    
    private func refreshFromTMDB() {
        guard let tmdbIdString = tvShow.tmdbId,
              let tmdbId = Int(tmdbIdString) else { return }
        
        Task {
            do {
                let tmdbShow = try await TMDBAPIManager.shared.getTVShow(id: tmdbId)
                await MainActor.run {
                    tvShow.updateFromTMDB(tmdbShow)
                }
            } catch {
                print("Failed to refresh from TMDB: \(error)")
            }
        }
    }
} 
