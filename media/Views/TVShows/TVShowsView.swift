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

        var id: Self { self }
    }

    @State private var filterOption: FilterOption = .all

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
                }
            }
            .filter { tvShow in
                searchQuery.isEmpty || tvShow.name.localizedCaseInsensitiveContains(searchQuery)
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
