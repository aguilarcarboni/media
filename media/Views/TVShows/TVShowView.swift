//
//  TVShowView.swift
//  media
//
//  Created by Andrés on 28/6/2025.
//

import SwiftUI
import SwiftData

// EpisodeView reference

struct TVShowView: View {
    @Bindable var tvShow: TVShow
    var isPreview: Bool = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // Toolbar state
    @State private var showingDeleteAlert: Bool = false
    @State private var tempRating: Double
    
    // Episode list state
    @State private var episodeResults: [TMDBEpisode] = []
    @State private var isLoadingEpisodes: Bool = false
    @State private var episodeErrorMessage: String = ""
    @State private var showEpisodeError: Bool = false

    // Episode selection state
    @State private var presentingSavedEpisode: Episode?
    @State private var selectedTMDBEpisode: TMDBEpisode?
    @State private var showingEpisodePreview = false
    
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
                
                // Episodes list
                if isLoadingEpisodes {
                    ProgressView("Loading episodes…")
                        .frame(maxWidth: .infinity)
                } else if !episodeResults.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Episodes (") + Text(String(episodeResults.count)) + Text(")").font(.headline)
                        ForEach(episodeResults.prefix(20), id: \.id) { ep in
                            Button(action: { selectEpisode(ep) }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("S\(ep.seasonNumber)E\(ep.episodeNumber) • \(ep.name)")
                                        .font(.subheadline)
                                    if let air = ep.airDate {
                                        Text(air)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.plain)
                        }
                        if episodeResults.count > 20 {
                            Text("Showing first 20 episodes")
                                .font(.caption)
                                .foregroundStyle(.secondary)
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
                    Button(action: {
                        Task { await addTVShowAndEpisodes(); dismiss() }
                    }) { Image(systemName: "plus") }
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
        .alert("Error", isPresented: $showEpisodeError) { Button("OK") {} } message: { Text(episodeErrorMessage) }
        // Episode sheets
        .sheet(item: $presentingSavedEpisode) { ep in
            NavigationStack { EpisodeView(episode: ep) }
        }
        .sheet(isPresented: $showingEpisodePreview) {
            if let epDetails = selectedTMDBEpisode {
                let previewEpisode = Episode(
                    tmdbId: epDetails.id,
                    name: epDetails.name,
                    overview: epDetails.overview,
                    seasonNumber: epDetails.seasonNumber,
                    episodeNumber: epDetails.episodeNumber,
                    airDate: epDetails.airDate,
                    runtime: epDetails.runtime,
                    tmdbRating: epDetails.voteAverage,
                    stillPath: epDetails.stillPath
                )
                NavigationStack { EpisodeView(episode: previewEpisode, isPreview: true) }
            }
        }
        .task(id: tvShow.tmdbId) {
            await loadEpisodes()
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

    // MARK: – Episode loading
    private func loadEpisodes() async {
        guard episodeResults.isEmpty, let idString = tvShow.tmdbId, let id = Int(idString), let seasons = tvShow.numberOfSeasons, seasons > 0 else { return }
        isLoadingEpisodes = true
        do {
            let eps = try await TMDBAPIManager.shared.getAllEpisodes(tvId: id, numberOfSeasons: seasons)
            await MainActor.run {
                self.episodeResults = eps
                self.isLoadingEpisodes = false
            }
        } catch {
            if error is CancellationError { return }
            await MainActor.run {
                self.episodeErrorMessage = error.localizedDescription
                self.showEpisodeError = true
                self.isLoadingEpisodes = false
            }
        }
    }

    // MARK: – Add TV Show & Episodes
    @MainActor
    private func addTVShowAndEpisodes() async {
        modelContext.insert(tvShow)
        do { try modelContext.save() } catch { return }
        guard let idStr = tvShow.tmdbId, let id = Int(idStr), let seasons = tvShow.numberOfSeasons else { return }
        do {
            let eps = try await TMDBAPIManager.shared.getAllEpisodes(tvId: id, numberOfSeasons: seasons)
            let existing: [Episode] = (try? modelContext.fetch(FetchDescriptor<Episode>())) ?? []
            let existingIds = Set(existing.compactMap { $0.tmdbId })
            for ep in eps {
                if existingIds.contains(ep.id) { continue }
                let episodeEntity = Episode(
                    tmdbId: ep.id,
                    name: ep.name,
                    overview: ep.overview,
                    seasonNumber: ep.seasonNumber,
                    episodeNumber: ep.episodeNumber,
                    airDate: ep.airDate,
                    runtime: ep.runtime,
                    tmdbRating: ep.voteAverage,
                    stillPath: ep.stillPath,
                    tvShow: tvShow
                )
                modelContext.insert(episodeEntity)
            }
            try? modelContext.save()
        } catch {
            // ignore episode save errors
        }
    }

    private func selectEpisode(_ ep: TMDBEpisode) {
        let idInt = ep.id
        if let existing = try? modelContext.fetch(FetchDescriptor<Episode>(predicate: #Predicate { $0.tmdbId == idInt })).first {
            presentingSavedEpisode = existing
        } else {
            selectedTMDBEpisode = ep
            showingEpisodePreview = true
        }
    }
} 
