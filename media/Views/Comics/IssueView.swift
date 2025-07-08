//
//  IssueView.swift
//  media
//
//  Created by AI on 07/07/2025.
//
//  Displays a single comic issue (Comic model) and allows marking read/unread and rating.
//

import SwiftUI
import SwiftData

struct IssueView: View {
    @Bindable var comic: Comic
    var isPreview: Bool = false

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // Rating control
    @State private var tempRating: Double
    @State private var showingRatingSheet = false
    @State private var showingDeleteAlert = false

    init(comic: Comic, isPreview: Bool = false) {
        self._comic = Bindable(wrappedValue: comic)
        self.isPreview = isPreview
        _tempRating = State(initialValue: comic.rating ?? 0.5)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(alignment: .top, spacing: 16) {
                    // Details
                    VStack(alignment: .leading, spacing: 6) {
                        if let series = comic.seriesName {
                            Label(series, systemImage: "book.closed")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if let issue = comic.issueNumber {
                            Label("Issue #\(issue)", systemImage: "number.circle")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if let pubDate = comic.publicationDate {
                            Label {
                                Text(pubDate)
                            } icon: {
                                Image(systemName: "calendar")
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                        if let pages = comic.pageCount {
                            Label("\(pages) pages", systemImage: "doc")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if let rating = comic.rating {
                            Label {
                                Text("Personal: \((rating * 10), specifier: "%.0f%%")")
                            } icon: {
                                Image(systemName: "star.circle.fill")
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    // Cover
                    AsyncImage(url: comic.coverURL) { img in
                        img
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Rectangle()
                            .fill(.secondary.opacity(0.3))
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.secondary)
                            }
                    }
                    .frame(width: 120, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                if let synopsis = comic.synopsis, !synopsis.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Synopsis")
                            .font(.headline)
                        Text(synopsis)
                            .font(.body)
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                let creators = [comic.writers, comic.artists].compactMap { $0 }.joined(separator: ", ")
                if !creators.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Creators").font(.headline)
                        Text(creators).font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                if let chars = comic.characters, !chars.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Characters").font(.headline)
                        Text(chars).font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                if let universe = comic.concepts, !universe.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Universe / Continuity").font(.headline)
                        Text(universe).font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                if let events = comic.storyArcs, !events.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Event / Story Arcs").font(.headline)
                        Text(events).font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                if let eventsType = comic.eventType, !eventsType.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Event Type").font(.headline)
                        Text(eventsType).font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                if let related = comic.relatedIssues, !related.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Related Issues (Tie-ins)").font(.headline)
                        Text(related).font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Backdrop / Cover image
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: comic.coverURL) { img in
                        img
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.secondary.opacity(0.3))
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.secondary)
                            }
                    }
                    .frame(height: 200)
                    .clipped()
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding()
        }
        .navigationTitle(comic.title)
        .toolbar {
            if isPreview {
                ToolbarItem(placement: .cancellationAction) { Button(action: { dismiss() }) { Image(systemName: "xmark") } }
                ToolbarItem(placement: .confirmationAction) { Button(action: { modelContext.insert(comic); dismiss() }) { Image(systemName: "plus") } }
            } else {
                // Read / Unread toggle
                ToolbarItem() { Button { toggleRead() } label: { Image(systemName: comic.read ? "checkmark.circle.fill" : "circle") } }
                if comic.read {
                    ToolbarItem {
                        Menu {
                            Stepper(value: $tempRating, in: 0...10, step: 0.1) {
                                Text(String(format: "%.0f%%", tempRating * 10))
                            }
                            Button("Save") { saveRating() }
                        } label: { Image(systemName: comic.rating != nil ? "star.circle.fill" : "star.circle") }
                    }
                }
                // Delete button
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .destructive) { showingDeleteAlert = true } label: { Image(systemName: "trash") }
                        .tint(.red)
                }

                // Overflow menu
                ToolbarItem() {
                    Menu {
                        if comic.comicVineId != nil {
                            Button("Refresh from Comic Vine") { refreshFromComicVine() }
                        }
                    } label: { Image(systemName: "ellipsis") }
                }
            }
        }
        .sheet(isPresented: $showingRatingSheet) { ratingSheet }
        .alert("Delete Issue?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) { modelContext.delete(comic); dismiss() }
            Button("Cancel", role: .cancel) { }
        } message: { Text("This action cannot be undone.") }
    }

    private func saveRating() {
        comic.rating = tempRating
        comic.updated = Date()
    }

    private func toggleRead() {
        if comic.read { comic.markAsUnread() } else { comic.markAsRead() }
    }

    // Refresh comic issue details from ComicVine
    private func refreshFromComicVine() {
        guard let id = comic.comicVineId else { return }
        Task {
            do {
                let details = try await ComicVineAPIManager.shared.getIssue(id: id)
                await MainActor.run {
                    comic.updateFromComicVine(details)
                }
            }
        }
    }

    private var ratingSheet: some View {
        NavigationStack {
            Form {
                Section("Your Rating") {
                    Slider(value: $tempRating, in: 0...10, step: 0.1)
                    HStack { Spacer(); Text(String(format: "%.1f (%.0f%%)", tempRating, tempRating * 10)).font(.title2); Spacer() }
                }
            }
            .navigationTitle("Rate Issue")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingRatingSheet = false } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { saveRating(); showingRatingSheet = false } }
            }
        }
    }

    @ViewBuilder private func infoRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label + ":").font(.subheadline).bold()
            Text(value).font(.subheadline)
            Spacer()
        }
    }
} 