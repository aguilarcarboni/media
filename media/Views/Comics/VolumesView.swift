//
//  VolumesView.swift
//  media
//
//  Created by AI on 07/07/2025.
//
//  Lists comic volumes fetched from ComicVine.
//

import SwiftUI
import SwiftData

struct VolumesView: View {
    @Query private var volumes: [Volume]
    @State private var selectedVolume: Volume?
    @State private var searchQuery = ""

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

    private var filteredVolumes: [Volume] {
        volumes
            .filter { vol in
                switch filterOption {
                case .all:
                    return true
                case .withSummary:
                    return vol.summary != nil && !(vol.summary!.isEmpty)
                case .noSummary:
                    return vol.summary == nil || vol.summary!.isEmpty
                }
            }
            .filter { vol in
                searchQuery.isEmpty || vol.name.localizedCaseInsensitiveContains(searchQuery)
            }
            .sorted { lhs, rhs in
                switch sortOption {
                case .titleAZ:
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                case .titleZA:
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedDescending
                case .yearNewest:
                    return (lhs.startYear ?? 0) > (rhs.startYear ?? 0)
                case .yearOldest:
                    return (lhs.startYear ?? 0) < (rhs.startYear ?? 0)
                case .issuesHighLow:
                    return (lhs.countOfIssues ?? -1) > (rhs.countOfIssues ?? -1)
                case .issuesLowHigh:
                    let l = lhs.countOfIssues ?? Int.max
                    let r = rhs.countOfIssues ?? Int.max
                    return l < r
                }
            }
    }

    var body: some View {
        VStack(spacing: 0) {
            if volumes.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    VStack(spacing: 8) {
                        Text("No Volumes Yet").font(.title2).bold()
                        Text("Use Search to add series to your library").font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }
                }
                .padding().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredVolumes) { volume in
                        Button(action: { selectedVolume = volume }) {
                            VolumeRowView(volume: volume)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Volumes")
        .searchable(text: $searchQuery)
        .sheet(item: $selectedVolume) { vol in
            NavigationStack { VolumeView(volume: vol) }
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

// Row View for volume list
private struct VolumeRowView: View {
    @Bindable var volume: Volume
    var body: some View {
        HStack {
            AsyncImage(url: volume.thumbnailURL) { img in
                img.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle().fill(.secondary.opacity(0.2)).overlay { Image(systemName: "photo") }
            }
            .frame(width: 40, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 4) {
                Text(volume.name).font(.headline)
                HStack {
                    if let year = volume.startYear { Text(String(year)).font(.caption).foregroundStyle(.secondary) }
                }
            }
            Spacer()
        }
    }
} 