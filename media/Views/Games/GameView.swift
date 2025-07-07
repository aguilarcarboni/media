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
                        // Played status
                        HStack {
                            Image(systemName: game.played ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(game.played ? .green : .secondary)
                                .font(.title2)
                            Text(game.played ? "Played" : "Not Played")
                                .font(.headline)
                                .foregroundStyle(game.played ? .green : .secondary)
                        }

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

                            if let releaseDate = game.releaseDate {
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
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Summary
                if let summary = game.summary, !summary.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Summary").font(.headline)
                        Text(summary).font(.body)
                    }
                    .padding().background(.regularMaterial).cornerRadius(8)
                }
                
                // Additional details
                VStack(alignment: .leading, spacing: 8) {
                    Text("Details").font(.headline)
                    VStack(spacing: 8) {
                        HStack { Text("Added:"); Spacer(); Text(game.created, format: .dateTime.day().month().year()) }
                        if game.updated != game.created {
                            HStack { Text("Updated:"); Spacer(); Text(game.updated, format: .dateTime.day().month().year()) }
                        }
                        if let igdbId = game.igdbId {
                            HStack { Text("IGDB ID:"); Spacer(); Text(igdbId).foregroundStyle(.secondary) }
                        }
                        if game.rating != nil && game.igdbRating != nil {
                            HStack { Text("Your Rating:"); Spacer(); Text("⭐ \(game.rating!, specifier: "%.1f")") }
                            HStack { Text("IGDB Rating:"); Spacer(); Text("⭐ \(game.igdbRating!, specifier: "%.1f")") }
                        }
                    }
                }
                .padding().background(.regularMaterial).cornerRadius(8)
                Spacer()
            }
            .padding()
        }
        .toolbar {
            if isPreview {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        modelContext.insert(game)
                        dismiss()
                    }
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

