//
//  IssuesView.swift
//  media
//
//  Created by AI on 07/07/2025.
//
//  Lists all comic issues stored in the library.
//

import SwiftUI
import SwiftData

struct IssuesView: View {
    @Query private var comics: [Comic]
    @State private var selectedComic: Comic?
    @State private var showingCreateSheet = false

    // Filtering options – simple for now
    enum FilterOption: String, CaseIterable, Identifiable {
        case all = "All"
        case withSummary = "With Summary"
        case noSummary = "No Summary"
        var id: Self { self }
    }
    @State private var filterOption: FilterOption = .all

    // Sorting options
    enum SortOption: String, CaseIterable, Identifiable {
        case titleAZ = "Title A-Z"
        case titleZA = "Title Z-A"
        case yearNewest = "Year Newest"
        case yearOldest = "Year Oldest"
        case issuesHighLow = "Issues High-Low"
        case issuesLowHigh = "Issues Low-High"
        var id: Self { self }
    }
    @State private var sortOption: SortOption = .titleAZ

    private var filteredComics: [Comic] {
        var comicsToShow = comics
        if filterOption != .all {
            comicsToShow = comics.filter { comic in
                if filterOption == .withSummary {
                    return comic.synopsis != nil
                } else {
                    return comic.synopsis == nil
                }
            }
        }
        return comicsToShow
    }

    var body: some View {
        VStack(spacing: 0) {
            if comics.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "book")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    VStack(spacing: 8) {
                        Text("No Issues Yet").font(.title2).bold()
                        Text("Add your first comic issue to get started")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    Button(action: { showingCreateSheet = true }) {
                        Label("Add Issue", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $selectedComic) {
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
        .navigationTitle("Issues")
        .sheet(item: $selectedComic) { comic in
            NavigationStack { IssueView(comic: comic) }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Picker("Filter", selection: $filterOption) {
                        ForEach(FilterOption.allCases) { Text($0.rawValue).tag($0) }
                    }
                } label: { Image(systemName: "line.3.horizontal.decrease.circle") }
            }
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Picker("Sort", selection: $sortOption) {
                        ForEach(SortOption.allCases) { Text($0.rawValue).tag($0) }
                    }
                } label: { Image(systemName: "arrow.up.arrow.down") }
            }
        }
    }
}

private struct ComicRowView: View {
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
                VStack(alignment: .leading, spacing: 4) {
                    if let series = comic.seriesName {
                        Text("\(series)").font(.caption).foregroundStyle(.secondary)
                    }
                    if let issue = comic.issueNumber {
                        Text("#\(issue)").font(.caption).foregroundStyle(.secondary)
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
