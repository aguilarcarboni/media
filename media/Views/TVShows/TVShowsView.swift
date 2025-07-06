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
    @State private var showingCreateSheet = false
    @State private var showingImportSheet = false
    @State private var searchQuery = ""
    
    var body: some View {
        VStack(spacing: 0) {
            if tvShows.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "tv")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    
                    VStack(spacing: 8) {
                        Text("No TV Shows Yet")
                            .font(.title2)
                            .bold()
                        
                        Text("Add your first TV show to get started")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button(action: { showingCreateSheet = true }) {
                        Label("Add TV Show", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(tvShows) { tvShow in
                        TVShowRowView(tvShow: tvShow)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedTVShow = tvShow }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("TV Shows")
        .sheet(isPresented: $showingCreateSheet) {
            CreateTVShowView()
        }
        .sheet(isPresented: $showingImportSheet) {
            TVShowsCSVImportView()
        }
        .sheet(item: $selectedTVShow) { tvShow in
            NavigationStack {
                TVShowView(tvShow: tvShow)
                    .navigationTitle(tvShow.name)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { showingImportSheet = true }) {
                    Label("Import CSV", systemImage: "doc.text")
                }
                .help("Import TV shows from CSV file")
                
                Button(action: { showingCreateSheet = true }) {
                    Label("Add TV Show", systemImage: "plus")
                }
                .help("Add new TV show")
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        .searchable(text: $searchQuery)
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
                
                HStack {
                    if let year = tvShow.year {
                        Text(String(year))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let genres = tvShow.genres {
                        Text("\(genres)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let rating = tvShow.displayRating {
                        Text("\(rating, specifier: "%.1f")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let numberOfSeasons = tvShow.numberOfSeasons {
                        Text("\(numberOfSeasons) season\(numberOfSeasons == 1 ? "" : "s")")
                            .font(.caption)
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