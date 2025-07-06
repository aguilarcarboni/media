//
//  ComicsView.swift
//  media
//
//  Created by Andrés on 6/7/2025.
//

import SwiftUI
import SwiftData

struct ComicsView: View {
    @Query private var comics: [Comic]
    @State private var selectedComic: Comic?
    @State private var showingCreateSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            if comics.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "book").font(.system(size: 48)).foregroundStyle(.secondary)
                    VStack(spacing: 8) {
                        Text("No Comics Yet").font(.title2).bold()
                        Text("Add your first comic to get started").font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }
                    Button(action: { showingCreateSheet = true }) { Label("Add Comic", systemImage: "plus") }
                        .buttonStyle(.borderedProminent)
                }
                .padding().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(comics) { comic in
                        Button(action: { selectedComic = comic }) {
                            ComicRowView(comic: comic)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Comics")
        .sheet(isPresented: $showingCreateSheet) { CreateComicView() }
        .sheet(item: $selectedComic) { comic in
            NavigationStack { ComicView(comic: comic) }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingCreateSheet = true }) {
                    Label("Add Comic", systemImage: "plus")
                }.help("Add new comic").keyboardShortcut("n", modifiers: .command)
            }
        }
    }
}

struct ComicRowView: View {
    let comic: Comic
    var body: some View {
        HStack {
            AsyncImage(url: comic.thumbnailURL) { img in
                img.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle().fill(.secondary.opacity(0.2)).overlay { Image(systemName: "photo") }
            }
            .frame(width: 40, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(comic.title).font(.headline).strikethrough(comic.read)
                HStack {
                    if let issue = comic.issueNumber {
                        Text("#\(issue)").font(.caption).foregroundStyle(.secondary)
                    }
                    if let series = comic.seriesName {
                        Text("• \(series)").font(.caption).foregroundStyle(.secondary)
                    }
                    if let rating = comic.rating {
                        Text("• ⭐ \(rating, specifier: "%.1f")").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
            if comic.read {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            }
        }
    }
} 