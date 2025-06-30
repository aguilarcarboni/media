//
//  TVShowsView.swift
//  media
//
//  Created by Andrés on 28/6/2025.
//

import SwiftUI
import SwiftData

struct TVShowsView: View {
    let tvShows: [TVShow]
    @Binding var selectedTVShow: TVShow?
    @Binding var showingTVShowDetail: Bool
    @Binding var showingCreateSheet: Bool
    @Binding var showingImportSheet: Bool
    
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
                        Button(action: {
                            selectedTVShow = tvShow
                            showingTVShowDetail = true
                        }) {
                            TVShowRowView(tvShow: tvShow)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("TV Shows (\(tvShows.count))")
        .sheet(isPresented: $showingCreateSheet) {
            CreateTVShowView()
        }
        .sheet(isPresented: $showingImportSheet) {
            TVShowsCSVImportView()
        }
        .sheet(isPresented: $showingTVShowDetail) {
            if let selectedTVShow = selectedTVShow {
                NavigationStack {
                    TVShowView(tvShow: selectedTVShow)
                        .navigationTitle(selectedTVShow.name)
                }
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
    }
}

struct TVShowRowView: View {
    let tvShow: TVShow
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(tvShow.name)
                    .font(.headline)
                    .strikethrough(tvShow.watched)
                
                HStack {
                    if let year = tvShow.year {
                        Text("\(year)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let genres = tvShow.genres {
                        Text("• \(genres)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let rating = tvShow.displayRating {
                        Text("• ⭐ \(rating, specifier: "%.1f")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let numberOfSeasons = tvShow.numberOfSeasons {
                        Text("• \(numberOfSeasons) season\(numberOfSeasons == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if tvShow.watched {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
    }
} 