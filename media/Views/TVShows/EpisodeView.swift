//  EpisodeView.swift
//  media
//
//  Created by AI on 08/07/2025.
//
//  Displays a single episode (Episode model) with watched/rating controls.

import SwiftUI
import SwiftData

struct EpisodeView: View {
    @Bindable var episode: Episode
    var isPreview: Bool = false

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // Rating state
    @State private var tempRating: Double
    @State private var showingRatingSheet = false
    @State private var showingDeleteAlert = false

    init(episode: Episode, isPreview: Bool = false) {
        self._episode = Bindable(wrappedValue: episode)
        self.isPreview = isPreview
        _tempRating = State(initialValue: episode.rating ?? 0.5)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(alignment: .top, spacing: 16) {
                    // Details
                    VStack(alignment: .leading, spacing: 6) {
                        if let season = episode.seasonNumber {
                            Label("Season \(season)", systemImage: "tv" )
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if let epNum = episode.episodeNumber {
                            Label("Episode #\(epNum)", systemImage: "number.circle")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if let air = episode.airDate {
                            Label {
                                Text(air)
                            } icon: { Image(systemName: "calendar") }
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if let runtime = episode.runtime {
                            Label("\(runtime) min", systemImage: "clock")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if let rating = episode.rating {
                            Label {
                                Text("Personal: \(rating * 10, specifier: "%.0f%%")")
                            } icon: { Image(systemName: "star.circle.fill") }
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if let tmdb = episode.tmdbRating {
                            Label {
                                Text("TMDB: \(tmdb * 10, specifier: "%.0f%%")")
                            } icon: { Image(systemName: "star.circle") }
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    // Still image
                    AsyncImage(url: episode.thumbnailURL) { img in
                        img.resizable().aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Rectangle().fill(.secondary.opacity(0.3)).overlay {
                            Image(systemName: "photo").font(.system(size: 24)).foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 120, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Overview
                if let ov = episode.overview, !ov.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Overview").font(.headline)
                        Text(ov).font(.body)
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Backdrop / still image enlarged
                ZStack {
                    AsyncImage(url: episode.stillURL ?? episode.thumbnailURL) { img in
                        img.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 8).fill(.secondary.opacity(0.3)).overlay {
                            Image(systemName: "photo").font(.system(size: 48)).foregroundStyle(.secondary)
                        }
                    }
                    .frame(height: 200)
                    .clipped()
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding()
        }
        .navigationTitle(episode.name)
        .toolbar {
            if isPreview {
                ToolbarItem(placement: .cancellationAction) { Button(action: { dismiss() }) { Image(systemName: "xmark") } }
                ToolbarItem(placement: .confirmationAction) { Button(action: { modelContext.insert(episode); dismiss() }) { Image(systemName: "plus") } }
            } else {
                // Watched toggle
                ToolbarItem() {
                    Button { toggleWatched() } label: { Image(systemName: episode.watched ? "checkmark.circle.fill" : "circle") }
                }

                // Rating menu (only when watched)
                if episode.watched {
                    ToolbarItem {
                        Menu {
                            Stepper(value: $tempRating, in: 0...10, step: 0.1) {
                                Text(String(format: "%.0f%%", tempRating * 10))
                            }
                            Button("Save") { saveRating() }
                        } label: {
                            Image(systemName: episode.rating != nil ? "star.circle.fill" : "star.circle")
                        }
                    }
                }

                // Delete button
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .destructive) { showingDeleteAlert = true } label: { Image(systemName: "trash") }.tint(.red)
                }
            }
        }
        .sheet(isPresented: $showingRatingSheet) { ratingSheet }
        .alert("Delete Episode?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) { modelContext.delete(episode); dismiss() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This action cannot be undone.") }
    }

    private func toggleWatched() {
        if episode.watched { episode.markAsUnwatched() } else { episode.markAsWatched() }
    }

    private func saveRating() {
        episode.rating = tempRating
        episode.updated = Date()
    }

    private var ratingSheet: some View {
        NavigationStack {
            Form {
                Section("Your Rating") {
                    Slider(value: $tempRating, in: 0...10, step: 0.1)
                    HStack { Spacer(); Text(String(format: "%.1f (%.0f%%)", tempRating, tempRating * 10)).font(.title2); Spacer() }
                }
            }
            .navigationTitle("Rate Episode")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingRatingSheet = false } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { saveRating(); showingRatingSheet = false } }
            }
        }
    }
}

#Preview {
    // Dummy preview episode
    let dummy = Episode(name: "Pilot", overview: "In the series premiere, ...", seasonNumber: 1, episodeNumber: 1, runtime: 42)
    return EpisodeView(episode: dummy)
} 
