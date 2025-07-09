//
//  VolumeView.swift
//  media
//
//  Created by AI on 07/07/2025.
//

import SwiftUI
import SwiftData

struct VolumeView: View {

    @Bindable var volume: Volume
    var isPreview: Bool = false

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // Issues list state
    @State private var issueResults: [ComicVineIssueSearchResult] = []
    @State private var isLoadingIssues = false
    @State private var errorMessage = ""
    @State private var showError = false

    // Teams derived from issues – no async state needed

    // Issue selection
    @State private var presentingSavedComic: Comic?
    @State private var selectedIssueDetails: ComicVineIssueDetails?
    @State private var showingIssuePreview = false

    // Rating state
    @State private var tempRating: Double = 0.5
    @State private var showingRatingSheet = false
    
    // Delete confirmation alert state
    @State private var showingDeleteAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(alignment: .top, spacing: 16) {
                    // Details
                    VStack(alignment: .leading, spacing: 6) {
                        if let year = volume.startYear {
                            Label(String(year), systemImage: "calendar")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if let publisher = volume.publisher {
                            Label(publisher, systemImage: "building.2")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if let issues = volume.countOfIssues {
                            Label("\(issues) issues", systemImage: "rectangle.grid.2x2")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if let rating = volume.rating {
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
                    AsyncImage(url: volume.coverURL) { img in
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
                if let summary = volume.summary {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Summary").font(.headline)
                        Text(summary).font(.body)
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Issues list section
                if isLoadingIssues {
                    ProgressView("Loading issues…")
                        .frame(maxWidth: .infinity)
                } else if !issueResults.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Issues (") + Text(String(issueResults.count)) + Text(")").font(.headline)
                        ForEach(issueResults.prefix(20)) { issue in
                            Button(action: { selectIssue(issue) }) {
                                HStack {
                                    AsyncImage(url: issue.thumbnailURL) { img in
                                        img.resizable().aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Rectangle().fill(.secondary.opacity(0.2)).overlay { Image(systemName: "photo") }
                                    }
                                    .frame(width: 40, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(issue.title).font(.subheadline)
                                        if issue.issueNumber != 0 {
                                            Text("#\(issue.issueNumber)").font(.caption).foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundStyle(.secondary)
                                }
                            }.buttonStyle(.plain)
                        }
                        if issueResults.count > 20 {
                            Text("Showing first 20 issues").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                // Characters section (aggregated)
                let chars = aggregatedCharacters
                if !chars.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Characters (") + Text(String(chars.count)) + Text(")").font(.headline)
                        Text(chars.prefix(30).joined(separator: ", "))
                            .font(.body)
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                // Teams section (aggregated)
                let teams = aggregatedTeams
                if !teams.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Teams (") + Text(String(teams.count)) + Text(")").font(.headline)
                        Text(teams.prefix(30).joined(separator: ", "))
                            .font(.body)
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                // Backdrop / Cover image
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: volume.coverURL) { img in
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

                Spacer()
            }
            .padding()
        }
        .navigationTitle(volume.name)
        .toolbar {
            if isPreview {
                ToolbarItem(placement: .cancellationAction) { Button(action: { dismiss() }) { Image(systemName: "xmark") } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        Task {
                            await addVolumeAndIssues()
                            dismiss()
                        }
                    }) { Image(systemName: "plus") }
                }
            }
            else {
                // Delete button
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .destructive) { showingDeleteAlert = true } label: { Image(systemName: "trash") }
                        .tint(.red)
                }

                // Read / Unread toggle
                ToolbarItem() {
                    Button { toggleRead() } label: { Image(systemName: volume.read ? "checkmark.circle.fill" : "circle") }
                }

                // Rating menu (only when read)
                if volume.read {
                    ToolbarItem {
                        Menu {
                            Stepper(value: $tempRating, in: 0...10, step: 0.1) {
                                Text(String(format: "%.0f%%", tempRating * 10))
                            }
                            Button("Save") { saveRating() }
                        } label: {
                            Image(systemName: volume.rating != nil ? "star.circle.fill" : "star.circle")
                        }
                    }
                }

                // Overflow menu
                ToolbarItem() {
                    Menu {
                        if volume.comicVineId != nil {
                            Button("Refresh from Comic Vine") { refreshFromComicVine() }
                        }
                    } label: { Image(systemName: "ellipsis") }
                }
            }
        }
        // Delete confirmation alert
        .alert("Delete Volume?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                modelContext.delete(volume)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
        // Error alert
        .alert("Error", isPresented: $showError) { Button("OK") {} } message: { Text(errorMessage) }
        // Issue sheets
        .sheet(item: $presentingSavedComic) { comic in
            NavigationStack { IssueView(comic: comic) }
        }
        .sheet(isPresented: $showingIssuePreview) {
            if let details = selectedIssueDetails {
                NavigationStack { IssueView(comic: details.toComic(), isPreview: true) }
            }
        }
        .sheet(isPresented: $showingRatingSheet) { ratingSheet }
        .task(id: volume.comicVineId) {
            await loadIssues()
        }
    }

    // MARK: – Fetch issues
    private func loadIssues() async {
        guard let id = volume.comicVineId else { return }
        isLoadingIssues = true
        do {
            let issues = try await ComicVineAPIManager.shared.issuesForVolume(volumeId: id)
            await MainActor.run {
                self.issueResults = issues
                self.isLoadingIssues = false

                // DEBUG print aggregated data
                let chars = aggregatedCharacters
                let teams = aggregatedTeams
            }
        } catch {
            if error is CancellationError { return }
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showError = true
                self.isLoadingIssues = false
            }
        }
    }

    private func selectIssue(_ issue: ComicVineIssueSearchResult) {
        let idStr = issue.id
        if let existing = try? modelContext.fetch(FetchDescriptor<Comic>(predicate: #Predicate { $0.comicVineId == idStr })).first {
            presentingSavedComic = existing
        } else {
            isLoadingIssues = true
            Task {
                do {
                    let details = try await ComicVineAPIManager.shared.getIssue(id: issue.id)
                    await MainActor.run {
                        self.selectedIssueDetails = details
                        self.isLoadingIssues = false
                        self.showingIssuePreview = true
                    }
                } catch {
                    await MainActor.run {
                        self.errorMessage = error.localizedDescription
                        self.showError = true
                        self.isLoadingIssues = false
                    }
                }
            }
        }
    }

    private func toggleRead() {
        if volume.read { volume.markAsUnread() } else { volume.markAsRead() }
    }

    private func saveRating() {
        volume.rating = tempRating
        volume.updated = Date()
    }

    // MARK: – Add Volume & Issues
    /// Saves the current preview `volume` to SwiftData and automatically fetches & stores all associated issues.
    @MainActor
    private func addVolumeAndIssues() async {
        #if DEBUG
        print("📥 Adding volume and its issues to context: \(volume.name) (ID: \(volume.comicVineId ?? -1))")
        #endif

        // 1. Insert the volume itself first
        modelContext.insert(volume)

        do {
            try modelContext.save()
        } catch {
            return // Bail early – no point continuing if the volume failed to save
        }

        // 2. Fetch all issues for this volume from ComicVine
        guard let volId = volume.comicVineId else {
            return
        }

        do {
            // Fetch up to 1,000 issues – ComicVine limits to 100 per request, but our helper handles paging via offset if needed later.
            let issueResults = try await ComicVineAPIManager.shared.issuesForVolume(volumeId: volId, limit: 1000)

            // Existing comic IDs set to avoid duplicates
            let existingComics: [Comic] = (try? modelContext.fetch(FetchDescriptor<Comic>())) ?? []
            let existingIds: Set<Int> = Set(existingComics.compactMap { $0.comicVineId })

            // --- NEW: Fetch detailed info for all missing issues in parallel ---
            var fetchedDetails: [ComicVineIssueDetails] = []
            try await withThrowingTaskGroup(of: ComicVineIssueDetails?.self) { group in
                for issue in issueResults where !existingIds.contains(issue.id) {
                    group.addTask {
                        do {
                            return try await ComicVineAPIManager.shared.getIssue(id: issue.id)
                        } catch {
                            // Swallow individual failures – we"ll fall back to lightweight insert later
                            return nil
                        }
                    }
                }
                for try await details in group {
                    if let details { fetchedDetails.append(details) }
                }
            }

            // Insert comics with full details
            for details in fetchedDetails {
                var comic = details.toComic()
                comic.volume = volume
                modelContext.insert(comic)
            }

            // Fallback: insert lightweight comics for any issue we didn"t get full details for
            let detailedIds = Set(fetchedDetails.map { $0.id })
            for issue in issueResults where !existingIds.contains(issue.id) && !detailedIds.contains(issue.id) {
                let comic = Comic(
                    comicVineId: issue.id,
                    title: issue.title,
                    issueNumber: issue.issueNumber,
                    seriesName: volume.name,
                    publicationDate: issue.year.map { String($0) },
                    synopsis: issue.overview,
                    thumbnailURLString: issue.thumbnailURL?.absoluteString,
                    volume: volume
                )
                modelContext.insert(comic)
            }

            // Persist all newly inserted comics
            try modelContext.save()
            #if DEBUG
            print("✅ Saved \(issueResults.count) issues for volume \(volume.name)")
            #endif
        } catch {
            #if DEBUG
            print("❌ Failed to fetch or save issues for volume: \(error.localizedDescription)")
            #endif
        }
    }

    // Refresh volume details from ComicVine
    private func refreshFromComicVine() {
        guard let id = volume.comicVineId else { return }
        Task {
            do {
                let details = try await ComicVineAPIManager.shared.getVolume(id: id)
                await MainActor.run {
                    volume.name = details.name
                    volume.startYear = details.startYear
                    volume.countOfIssues = details.issueCount
                    volume.summary = details.description
                    volume.coverURLString = details.coverURL
                    volume.thumbnailURLString = details.thumbnailURL
                    volume.publisher = details.publisher
                    volume.updated = Date()
                }
            } catch {
                #if DEBUG
                print("Failed to refresh from Comic Vine: \(error)")
                #endif
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
            .navigationTitle("Rate Volume")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingRatingSheet = false } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { saveRating(); showingRatingSheet = false } }
            }
        }
    }

    @ViewBuilder
    private func infoRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label + ":").font(.subheadline).bold()
            Text(value).font(.subheadline)
            Spacer()
        }
    }

    // MARK: – Derived data
    private var aggregatedCharacters: [String] {
        guard let issues = volume.issues else { return [] }
        var set = Set<String>()
        for comic in issues {
            if let charsStr = comic.characters {
                let parts = charsStr.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                set.formUnion(parts)
            }
        }
        return set.sorted()
    }

    private var aggregatedTeams: [String] {
        guard let issues = volume.issues else { return [] }
        var set = Set<String>()
        for comic in issues {
            if let teamStr = comic.teams {
                let parts = teamStr.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                set.formUnion(parts)
            }
        }
        return set.sorted()
    }
} 
