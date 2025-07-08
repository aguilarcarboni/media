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
    
    // Toolbar state
    @State private var showingDeleteAlert: Bool = false
    @State private var tempRating: Double
    
    // Custom initializer to configure state values
    init(tvShow: TVShow, isPreview: Bool = false) {
        self._tvShow = Bindable(wrappedValue: tvShow)
        self.isPreview = isPreview
        // Start rating at personal rating if available, then TMDB rating, else 0.5
        _tempRating = State(initialValue: tvShow.rating ?? tvShow.tmdbRating ?? 0.5)
    }
    
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
                            if let tmdbRating = tvShow.tmdbRating {
                                Label {
                                    Text("TMDB: \(tmdbRating * 10, specifier: "%.0f%%")")
                                } icon: {
                                    Image(systemName: "star.circle.fill")
                                }
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }
                            if let rating = tvShow.rating {
                                Label {
                                    Text("Personal: \(rating * 10, specifier: "%.0f%%")")
                                } icon: {
                                    Image(systemName: "star.circle.fill")
                                }
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }
                            if let creators = tvShow.creators {
                                Label(creators, systemImage: "person")
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
                    .frame(maxWidth: .infinity, alignment: .leading)
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
                ToolbarItem(placement: .cancellationAction) { Button(action: { dismiss() }) { Image(systemName: "xmark") } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { modelContext.insert(tvShow); dismiss() }) { Image(systemName: "plus") }
                }
            } else {
                // Delete TV show toolbar button
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .tint(.red)
                }

                // Watched / Unwatched toggle
                ToolbarItem() {
                    Button {
                        if tvShow.watched { tvShow.markAsUnwatched() } else { tvShow.markAsWatched() }
                    } label: {
                        Image(systemName: tvShow.watched ? "checkmark.circle.fill" : "circle")
                    }
                }

                // Rating menu (only when watched)
                if tvShow.watched {
                    ToolbarItem {
                        Menu {
                            Stepper(value: $tempRating, in: 0...10, step: 0.1) {
                                Text(String(format: "%.0f%%", tempRating * 10))
                            }
                            Button("Save") {
                                tvShow.rating = tempRating
                                tvShow.updated = Date()
                            }
                        } label: {
                            Image(systemName: tvShow.rating != nil ? "star.circle.fill" : "star.circle")
                        }
                    }
                }

                // Overflow menu
                ToolbarItem() {
                    Menu {
                        if tvShow.tmdbId != nil {
                            Button("Refresh from TMDB") { refreshFromTMDB() }
                        }
                    } label: { Image(systemName: "ellipsis") }
                }
            }
        }
        // Delete confirmation alert
        .alert("Delete TV Show?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                modelContext.delete(tvShow)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
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
