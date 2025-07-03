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
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header cover
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: game.coverURL) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle().fill(.secondary.opacity(0.3)).overlay {
                            Image(systemName: "photo").font(.system(size: 48)).foregroundStyle(.secondary)
                        }
                    }
                    .frame(height: 200).clipped()
                    LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(game.name).font(.largeTitle).bold().foregroundStyle(.white).shadow(color: .black, radius: 2)
                        HStack {
                            if let year = game.year {
                                Text("\(year)").font(.title3).foregroundStyle(.white.opacity(0.9))
                            }
                            if let rating = game.displayRating {
                                Text("⭐ \(rating, specifier: "%.1f")").font(.title3).foregroundStyle(.white.opacity(0.9))
                            }
                        }
                    }
                    .padding()
                }
                .cornerRadius(12)
                
                // Quick details
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: game.played ? "checkmark.circle.fill" : "circle").foregroundStyle(game.played ? .green : .secondary).font(.title2)
                        Text(game.played ? "Played" : "Not Played").font(.headline).foregroundStyle(game.played ? .green : .secondary)
                    }
                    if !game.platformList.isEmpty {
                        Label(game.platformList.joined(separator: ", "), systemImage: "desktopcomputer").font(.subheadline).foregroundStyle(.secondary)
                    }
                    if !game.genreList.isEmpty {
                        Label(game.genreList.joined(separator: ", "), systemImage: "tag").font(.subheadline).foregroundStyle(.secondary)
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
            ToolbarItemGroup(placement: .primaryAction) {
                Button(game.played ? "Mark Unplayed" : "Mark Played") {
                    if game.played { game.markAsUnplayed() } else { game.markAsPlayed() }
                }
            }
        }
    }
} 