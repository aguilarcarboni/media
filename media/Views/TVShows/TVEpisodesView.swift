//  TVEpisodesView.swift
//  media
//
//  Created by AI on 08/07/2025.
//
//  Shows a library list of all saved TV episodes. Selecting an episode opens EpisodeView.

import SwiftUI
import SwiftData

struct TVEpisodesView: View {
    @Query private var episodes: [Episode]
    @State private var selectedEpisode: Episode?
    @State private var searchQuery: String = ""

    // Simple sort options – by season/episode or name
    enum SortOption: String, CaseIterable, Identifiable {
        case seasonEpisode = "Season / Episode"
        case nameAZ = "Name A-Z"
        case nameZA = "Name Z-A"
        case ratingHighLow = "Rating High-Low"
        case ratingLowHigh = "Rating Low-High"

        var id: Self { self }
    }

    @State private var sortOption: SortOption = .seasonEpisode

    private var filteredEpisodes: [Episode] {
        episodes.filter { ep in
            searchQuery.isEmpty || ep.name.localizedCaseInsensitiveContains(searchQuery)
        }.sorted { lhs, rhs in
            switch sortOption {
            case .seasonEpisode:
                if (lhs.seasonNumber ?? 0) == (rhs.seasonNumber ?? 0) {
                    return (lhs.episodeNumber ?? 0) < (rhs.episodeNumber ?? 0)
                }
                return (lhs.seasonNumber ?? 0) < (rhs.seasonNumber ?? 0)
            case .nameAZ:
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            case .nameZA:
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedDescending
            case .ratingHighLow:
                return (lhs.rating ?? -1) > (rhs.rating ?? -1)
            case .ratingLowHigh:
                return (lhs.rating ?? Double.greatestFiniteMagnitude) < (rhs.rating ?? Double.greatestFiniteMagnitude)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if episodes.isEmpty {
                ContentUnavailableView("No Episodes", systemImage: "rectangle.stack", description: Text("Add a TV Show with episodes"))
            } else {
                List {
                    ForEach(filteredEpisodes) { ep in
                        EpisodeRowView(episode: ep)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedEpisode = ep }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Episodes")
        .sheet(item: $selectedEpisode) { ep in
            NavigationStack { EpisodeView(episode: ep) }
        }
        .searchable(text: $searchQuery)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Picker("Sort", selection: $sortOption) {
                        ForEach(SortOption.allCases) { opt in Text(opt.rawValue).tag(opt) }
                    }
                } label: { Image(systemName: "arrow.up.arrow.down") }
            }
        }
    }
}

struct EpisodeRowView: View {
    @Bindable var episode: Episode
    var body: some View {
        HStack {
            AsyncImage(url: episode.thumbnailURL) { img in
                img.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle().fill(.secondary.opacity(0.2)).overlay { Image(systemName: "photo") }
            }
            .frame(width: 40, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 4) {
                Text(episode.name).font(.headline)
                if let show = episode.tvShow {
                    Text(show.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 6) {
                    if let s = episode.seasonNumber, let e = episode.episodeNumber {
                        Text("S\(s)E\(e)").font(.subheadline).foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
            Button(action: {
                if episode.watched { episode.markAsUnwatched() } else { episode.markAsWatched() }
            }) {
                Image(systemName: episode.watched ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(episode.watched ? .green : .secondary)
            }
            .buttonStyle(.borderless)
        }
    }
}

#Preview {
    NavigationStack { TVEpisodesView() }
} 