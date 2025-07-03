//
//  GamesView.swift
//  media
//
//  Created by Andrés on 30/6/2025.
//

import SwiftUI
import SwiftData

struct GamesView: View {
    let games: [Game]
    @Binding var selectedGame: Game?
    @Binding var showingGameDetail: Bool
    @Binding var showingCreateSheet: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            if games.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "gamecontroller")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    VStack(spacing: 8) {
                        Text("No Games Yet").font(.title2).bold()
                        Text("Add your first game to get started")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    Button(action: { showingCreateSheet = true }) {
                        Label("Add Game", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(games) { game in
                        Button(action: {
                            selectedGame = game
                            showingGameDetail = true
                        }) {
                            GameRowView(game: game)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Games (\(games.count))")
        .sheet(isPresented: $showingCreateSheet) {
            CreateGameView()
        }
        .sheet(isPresented: $showingGameDetail) {
            if let selectedGame = selectedGame {
                NavigationStack { GameView(game: selectedGame).navigationTitle(selectedGame.name) }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingCreateSheet = true }) {
                    Label("Add Item", systemImage: "plus")
                }
                .help("Add new game")
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }
}

struct GameRowView: View {
    let game: Game
    var body: some View {
        HStack {
            AsyncImage(url: game.thumbnailURL) { img in
                img.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(.secondary.opacity(0.2))
                    .overlay { Image(systemName: "photo") }
            }
            .frame(width: 40, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading, spacing: 4) {
                Text(game.name).font(.headline).strikethrough(game.played)
                HStack {
                    if let year = game.year {
                        Text("\(year)").font(.caption).foregroundStyle(.secondary)
                    }
                    if !game.platformList.isEmpty {
                        Text("• \(game.platformList.joined(separator: ", "))").font(.caption).foregroundStyle(.secondary)
                    }
                    if let rating = game.displayRating {
                        Text("• ⭐ \(rating, specifier: "%.1f")").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
            if game.played {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            }
        }
    }
} 