//
//  TVShowsView.swift
//  media
//
//  Created by Andrés on 28/6/2025.
//

import SwiftUI
import SwiftData

struct TVShowsView: View {
    @Query private var tvShows: [TVShow]
    @State private var selectedTVShow: TVShow?
    @State private var searchQuery = ""
    
    // Filtering
    enum FilterOption: String, CaseIterable, Identifiable {
        case all = "All"
        case watched = "Watched"
        case unwatched = "Unwatched"
        case rated = "Rated"
        case unrated = "Unrated"

        var id: Self { self }
    }

    @State private var filterOption: FilterOption = .all

    // Sorting
    enum SortOption: String, CaseIterable, Identifiable {
        case nameAZ = "Name A-Z"
        case nameZA = "Name Z-A"
        case yearNewest = "Year Newest"
        case yearOldest = "Year Oldest"
        case ratingHighLow = "Rating High-Low"
        case ratingLowHigh = "Rating Low-High"

        var id: Self { self }
    }

    @State private var sortOption: SortOption = .nameAZ

    private var filteredTVShows: [TVShow] {
        tvShows
            .filter { tvShow in
                switch filterOption {
                case .all:
                    return true
                case .watched:
                    return tvShow.watched
                case .unwatched:
                    return !tvShow.watched
                case .rated:
                    return tvShow.rating != nil
                case .unrated:
                    return tvShow.rating == nil
                }
            }
            .filter { tvShow in
                searchQuery.isEmpty || tvShow.name.localizedCaseInsensitiveContains(searchQuery)
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
                case .ratingHighLow:
                    let lhsRating = lhs.rating ?? -1
                    let rhsRating = rhs.rating ?? -1
                    return lhsRating > rhsRating
                case .ratingLowHigh:
                    let lhsRating = lhs.rating ?? Double.greatestFiniteMagnitude
                    let rhsRating = rhs.rating ?? Double.greatestFiniteMagnitude
                    return lhsRating < rhsRating
                }
            }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if tvShows.isEmpty {
                ContentUnavailableView("No TV Shows", systemImage: "tv", description: Text("Add a TV Show"))
            } else {
                List {
                    ForEach(filteredTVShows) { tvShow in
                        TVShowRowView(tvShow: tvShow)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedTVShow = tvShow }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("TV Shows")
        .sheet(item: $selectedTVShow) { tvShow in
            NavigationStack {
                TVShowView(tvShow: tvShow)
                    .navigationTitle(tvShow.name)
            }
        }
        .searchable(text: $searchQuery)
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
    }
}

struct TVShowRowView: View {
    @Bindable var tvShow: TVShow
    
    var body: some View {
        HStack {
            AsyncImage(url: tvShow.thumbnailURL) { img in
                img.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(.secondary.opacity(0.2))
                    .overlay { Image(systemName: "photo") }
            }
            .frame(width: 40, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading, spacing: 4) {
                Text(tvShow.name)
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 4) {
                    if let creators = tvShow.creators {
                        Text(creators)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let year = tvShow.year {
                        Text(String(year))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                if tvShow.watched {
                    tvShow.markAsUnwatched()
                } else {
                    tvShow.markAsWatched()
                }
            }) {
                Image(systemName: tvShow.watched ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(tvShow.watched ? .green : .secondary)
            }
            .buttonStyle(.borderless)
        }
    }
} 
