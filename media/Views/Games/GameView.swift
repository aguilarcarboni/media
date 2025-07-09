//
//  GameView.swift
//  media
//
//  Created by Andrés on 30/6/2025.
//

import SwiftUI
import SwiftData

struct GameView: View {
    @Bindable var game: Game
    // Preview mode flag
    var isPreview: Bool = false
    // Environment
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // Toolbar State
    @State private var showingDeleteAlert: Bool = false
    @State private var tempRating: Double
    
    // Custom initializer
    init(game: Game, isPreview: Bool = false) {
        self._game = Bindable(wrappedValue: game)
        self.isPreview = isPreview
        _tempRating = State(initialValue: game.rating ?? game.igdbRating ?? 0.5)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Cover and quick details
                HStack(alignment: .top, spacing: 16) {
                    // Cover
                    AsyncImage(url: game.coverURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.secondary.opacity(0.3))
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.secondary)
                            }
                    }

                    // Game details
                    VStack(alignment: .leading, spacing: 12) {

                        // Quick details
                        VStack(alignment: .leading, spacing: 6) {
                            if !game.platformList.isEmpty {
                                Label(game.platformList.joined(separator: ", "), systemImage: "desktopcomputer")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            if !game.genreList.isEmpty {
                                Label(game.genreList.joined(separator: ", "), systemImage: "tag")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            // Year (if available)
                            if let year = game.year {
                                Label(String(year), systemImage: "calendar")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            if let releaseDate = game.releaseDate {
                                Label {
                                    Text(releaseDate, format: .dateTime.day().month().year())
                                } icon: {
                                    Image(systemName: "calendar")
                                }
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }

                            if let igdbRating = game.igdbRating {
                                Label {
                                    Text("IGDB: \(igdbRating * 10, specifier: "%.0f%%")")
                                } icon: {
                                    Image(systemName: "star.circle.fill")
                                }
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }

                            if let rating = game.rating {
                                Label {
                                    Text("Personal: \(rating * 10, specifier: "%.0f%%")")
                                } icon: {
                                    Image(systemName: "star.circle.fill")
                                }
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()
                    }

                    Spacer()
                }
                // Header now matches design of MovieView/TVShowView without card background
                
                // Summary
                if let summary = game.summary, !summary.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Summary").font(.headline)
                        Text(summary).font(.body)
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Platforms list as chips
                if !game.platformList.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Platforms").font(.headline)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                            ForEach(game.platformList, id: \.self) { platform in
                                Text(platform)
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

                // Genres list as chips
                if !game.genreList.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Genres").font(.headline)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                            ForEach(game.genreList, id: \.self) { genre in
                                Text(genre)
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

                // Backdrop / Cover image (matches MovieView/TVShowView layout)
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: game.coverURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.secondary.opacity(0.3))
                            .overlay {
                                Image(systemName: "photo")
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
                        modelContext.insert(game)
                        dismiss()
                    }) { Image(systemName: "plus") }
                }
            } else {
                // Delete button
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .destructive) { showingDeleteAlert = true } label: { Image(systemName: "trash") }
                        .tint(.red)
                }
                // Played toggle
                ToolbarItem() {
                    Button {
                        if game.played { game.markAsUnplayed() } else { game.markAsPlayed() }
                    } label: { Image(systemName: game.played ? "checkmark.circle.fill" : "circle") }
                }
                // Rating menu (only when played)
                if game.played {
                    ToolbarItem {
                        Menu {
                            Stepper(value: $tempRating, in: 0...10, step: 0.1) {
                                Text(String(format: "%.0f%%", tempRating * 10))
                            }
                            Button("Save") {
                                game.rating = tempRating
                                game.updated = Date()
                            }
                        } label: {
                            Image(systemName: game.rating != nil ? "star.circle.fill" : "star.circle")
                        }
                    }
                }
                // Overflow menu
                ToolbarItem() {
                    Menu {
                        if game.igdbId != nil { Button("Refresh from IGDB") { refreshFromIGDB() } }
                    } label: { Image(systemName: "ellipsis") }
                }
            }
        }
        // Delete alert
        .alert("Delete Game?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                modelContext.delete(game)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This action cannot be undone.") }
    }

    private func refreshFromIGDB() {
        guard let igdbIdString = game.igdbId,
              let igdbId = Int(igdbIdString) else { return }

        Task {
            do {
                let igdbGame = try await IGDBAPIManager.shared.getGame(id: igdbId)
                await MainActor.run {
                    game.updateFromIGDB(igdbGame)
                }
            } catch {
                print("Failed to refresh from IGDB: \(error)")
            }
        }
    }
} 

