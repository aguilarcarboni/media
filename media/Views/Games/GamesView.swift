//
//  GamesView.swift
//  media
//
//  Created by Andrés on 30/6/2025.
//

import SwiftUI
import SwiftData

struct GamesView: View {
    @Query private var games: [Game]
    @State private var selectedGame: Game?
    @State private var searchQuery = ""
    
    enum FilterOption: String, CaseIterable, Identifiable {
        case all = "All"
        case played = "Played"
        case unplayed = "Unplayed"
        var id: Self { self }
    }

    @State private var filterOption: FilterOption = .all

    // Sorting
    enum SortOption: String, CaseIterable, Identifiable {
        case nameAZ = "Name A-Z"
        case nameZA = "Name Z-A"
        case yearNewest = "Year Newest"
        case yearOldest = "Year Oldest"

        var id: Self { self }
    }

    @State private var sortOption: SortOption = .nameAZ

    private var filteredGames: [Game] {
        games
            .filter { game in
                switch filterOption {
                case .all: return true
                case .played: return game.played
                case .unplayed: return !game.played
                }
            }
            .filter { g in
                searchQuery.isEmpty ||
                g.name.localizedCaseInsensitiveContains(searchQuery)
            }
            .sorted { lhs, rhs in
                switch sortOption {
                case .nameAZ:
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                case .nameZA:
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedDescending
                case .yearNewest:
                    return (lhs.year ?? 0) > (rhs.year ?? 0)
                case .yearOldest:
                    return (lhs.year ?? 0) < (rhs.year ?? 0)
                }
            }
    }

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
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredGames) { game in
                        GameRowView(game: game)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedGame = game }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Games")
        .sheet(item: $selectedGame) { game in
            NavigationStack { GameView(game: game).navigationTitle(game.name) }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Picker("Filter", selection: $filterOption) {
                        ForEach(FilterOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Picker("Sort", selection: $sortOption) {
                        ForEach(SortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
            }
        }
        .searchable(text: $searchQuery)
    }
}

struct GameRowView: View {
    @Bindable var game: Game
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
                Text(game.name)
                    .font(.headline)
                HStack {
                    if let year = game.year {
                        Text(String(year)).font(.caption).foregroundStyle(.secondary)
                    }
                    if !game.platformList.isEmpty {
                        Text("\(game.platformList.joined(separator: ", "))").font(.caption).foregroundStyle(.secondary)
                    }
                    if let rating = game.displayRating {
                        Text("\(rating, specifier: "%.1f")").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
            Button(action: {
                if game.played {
                    game.markAsUnplayed()
                } else {
                    game.markAsPlayed()
                }
            }) {
                Image(systemName: game.played ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(game.played ? .green : .secondary)
            }
            .buttonStyle(.borderless)
        }
    }
} 