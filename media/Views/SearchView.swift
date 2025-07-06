import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    // Search state
    @State private var searchQuery: String = ""
    @State private var movieResults: [TMDBMovieSearchResult] = []
    @State private var tvResults: [TMDBTVShowSearchResult] = []
    @State private var isSearching = false
    // Category picker
    private enum Category: String, CaseIterable, Identifiable { case top = "Top Results", movies = "Movies", tv = "TV Shows"; var id: Self { self } }
    @State private var selectedCategory: Category = .top
    // Error handling
    @State private var showingError = false
    @State private var errorMessage = ""
    // Preview presentation
    @State private var selectedTMDBMovie: TMDBMovieDetails?
    @State private var isLoadingMovieDetails = false
    @State private var showingPreview = false
    // Saved movie presentation
    @State private var presentingSavedMovie: Movie?
    @State private var presentingSavedTVShow: TVShow?
    // Track whether the current query has been executed
    @State private var hasSearched = false
    // Add new state variables below existing ones
    @State private var savedMovieIDs: Set<String> = []
    @State private var savedTVIDs: Set<String> = []
    // Cache dictionaries for quick access
    @State private var savedMoviesByID: [String: Movie] = [:]
    @State private var savedTVShowsByID: [String: TVShow] = [:]
    @State private var selectedTMDBTVShow: TMDBTVShowDetails?
    @State private var showingTVPreview = false

    var body: some View {
        NavigationStack {
            Group {
                let hasAnyResults = !movieResults.isEmpty || !tvResults.isEmpty
                if isSearching {
                    ProgressView("Searching TMDB…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if hasSearched {
                    if !hasAnyResults {
                        VStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 32))
                                .foregroundStyle(.secondary)
                            Text("No results for \"\(searchQuery)\"")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            Picker("Category", selection: $selectedCategory) {
                                ForEach(Category.allCases) { cat in Text(cat.rawValue).tag(cat) }
                            }
                            .pickerStyle(.segmented)
                            .padding([.horizontal, .top])

                            LazyVStack(spacing: 12) {
                                switch selectedCategory {
                                case .movies:
                                    ForEach(movieResults) { movieSearchResultRow($0, isSaved: savedMovieIDs.contains(String($0.id))) }
                                case .tv:
                                    ForEach(tvResults) { tvShowSearchResultRow($0, isSaved: savedTVIDs.contains(String($0.id))) }
                                case .top:
                                    ForEach(movieResults.prefix(5)) { movieSearchResultRow($0, isSaved: savedMovieIDs.contains(String($0.id))) }
                                    ForEach(tvResults.prefix(5)) { tvShowSearchResultRow($0, isSaved: savedTVIDs.contains(String($0.id))) }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                } else {
                    VStack {
                        Spacer()
                        ContentUnavailableView("Search", systemImage: "magnifyingglass", description: Text(searchQuery.isEmpty ? "Start typing to search your media library…" : "Press enter to search…"))
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Search")
            .searchable(text: $searchQuery, prompt: "Search Movies & TV Shows")
            .onSubmit(of: .search) {
                Task { await performSearch() }
            }
            .onChange(of: searchQuery) { _ in
                hasSearched = false
                movieResults = []
                tvResults = []
            }
            // Preview sheet
            .sheet(isPresented: $showingPreview, onDismiss: refreshSavedCache) {
                if let details = selectedTMDBMovie {
                    NavigationStack { MovieView(movie: details.toMovie(), isPreview: true) }
                }
            }
            // TV Preview
            .sheet(isPresented: $showingTVPreview, onDismiss: refreshSavedCache) {
                if let details = selectedTMDBTVShow {
                    NavigationStack { TVShowView(tvShow: details.toTVShow(), isPreview: true) }
                }
            }
            // Saved movie sheet
            .sheet(item: $presentingSavedMovie, onDismiss: refreshSavedCache) { movie in
                NavigationStack { MovieView(movie: movie) }
            }
            // Saved TV show sheet
            .sheet(item: $presentingSavedTVShow, onDismiss: refreshSavedCache) { show in
                NavigationStack { TVShowView(tvShow: show) }
            }
        }
    }

    // MARK: – UI Helpers
    private func movieSearchResultRow(_ result: TMDBMovieSearchResult, isSaved: Bool) -> some View {
        Button(action: { selectMovie(result, isSaved: isSaved) }) {
            searchRowThumbnail(url: result.thumbnailURL, title: result.title, subtitle: subtitleMovie(result), trailingIcon: isSaved ? "checkmark.circle.fill" : "chevron.right", iconColor: isSaved ? .green : .secondary)
        }
        .buttonStyle(.plain)
    }

    private func tvShowSearchResultRow(_ result: TMDBTVShowSearchResult, isSaved: Bool) -> some View {
        Button(action: { selectTVShow(result, isSaved: isSaved) }) {
            searchRowThumbnail(url: TMDBAPIManager.shared.thumbnailURL(path: result.posterPath), title: result.name, subtitle: subtitleTV(result), trailingIcon: isSaved ? "checkmark.circle.fill" : "chevron.right", iconColor: isSaved ? .green : .secondary)
        }
        .buttonStyle(.plain)
    }

    private func searchRowThumbnail(url: URL?, title: String, subtitle: String, trailingIcon: String, iconColor: Color) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: url) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle().fill(.secondary.opacity(0.2)).overlay { Image(systemName: "photo") }
            }
            .frame(width: 50, height: 75).clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline).foregroundStyle(.primary).multilineTextAlignment(.leading)
                Text(subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }
            Spacer()
            Image(systemName: trailingIcon).foregroundStyle(iconColor)
        }
        .padding().cornerRadius(12).shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }

    private func subtitleMovie(_ result: TMDBMovieSearchResult) -> String {
        var parts: [String] = ["Movie"]
        if let year = result.year { parts.append(String(year)) }
        return parts.joined(separator: " • ")
    }

    private func subtitleTV(_ result: TMDBTVShowSearchResult) -> String {
        var parts: [String] = ["TV Show"]
        if let firstAirDate = result.firstAirDate, let year = DateFormatter.tmdbDateFormatter.date(from: firstAirDate).map({ Calendar.current.component(.year, from: $0) }) {
            parts.append(String(year))
        }
        return parts.joined(separator: " • ")
    }

    // MARK: – Actions
    @MainActor private func performSearch() async {
        guard !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isSearching = true
        do {
            async let movies = TMDBAPIManager.shared.searchMovieResults(query: searchQuery)
            async let tvs = TMDBAPIManager.shared.searchTVShowResults(query: searchQuery)
            self.movieResults = try await movies
            self.tvResults = try await tvs

            // Update saved cache sets
            let existingMovies = (try? modelContext.fetch(FetchDescriptor<Movie>())) ?? []
            savedMovieIDs = Set(existingMovies.compactMap { $0.tmdbId })
            var movieDict: [String: Movie] = [:]
            for movie in existingMovies {
                if let id = movie.tmdbId {
                    movieDict[id] = movie // later duplicates simply override earlier ones, avoiding a crash
                }
            }
            savedMoviesByID = movieDict

            let existingShows = (try? modelContext.fetch(FetchDescriptor<TVShow>())) ?? []
            savedTVIDs = Set(existingShows.compactMap { $0.tmdbId })
            var tvDict: [String: TVShow] = [:]
            for show in existingShows {
                if let id = show.tmdbId {
                    tvDict[id] = show
                }
            }
            savedTVShowsByID = tvDict
            self.isSearching = false
            self.hasSearched = true
        } catch {
            if error is CancellationError { return }
            self.errorMessage = error.localizedDescription
            self.showingError = true
            self.isSearching = false
        }
    }

    private func selectMovie(_ searchResult: TMDBMovieSearchResult, isSaved: Bool) {
        let movieIdStr = String(searchResult.id)
        if let existing = savedMoviesByID[movieIdStr] {
            presentingSavedMovie = existing
        } else {
            isLoadingMovieDetails = true
            Task {
                do {
                    let details = try await TMDBAPIManager.shared.getMovie(id: searchResult.id)
                    await MainActor.run {
                        self.selectedTMDBMovie = details
                        self.isLoadingMovieDetails = false
                        self.showingPreview = true
                    }
                } catch {
                    if error is CancellationError { return }
                    await MainActor.run {
                        self.errorMessage = error.localizedDescription
                        self.showingError = true
                        self.isLoadingMovieDetails = false
                    }
                }
            }
        }
    }

    private func selectTVShow(_ searchResult: TMDBTVShowSearchResult, isSaved: Bool) {
        let idStr = String(searchResult.id)
        if let existing = savedTVShowsByID[idStr] {
            presentingSavedTVShow = existing
        } else {
            isLoadingMovieDetails = true // reuse loading indicator
            Task {
                do {
                    let details = try await TMDBAPIManager.shared.getTVShow(id: searchResult.id)
                    await MainActor.run {
                        self.selectedTMDBTVShow = details
                        self.isLoadingMovieDetails = false
                        self.showingTVPreview = true
                    }
                } catch {
                    if error is CancellationError { return }
                    await MainActor.run {
                        self.errorMessage = error.localizedDescription
                        self.showingError = true
                        self.isLoadingMovieDetails = false
                    }
                }
            }
        }
    }

    private func refreshSavedCache() {
        let existingMovies = (try? modelContext.fetch(FetchDescriptor<Movie>())) ?? []
        savedMovieIDs = Set(existingMovies.compactMap { $0.tmdbId })
        var mDict: [String: Movie] = [:]
        for m in existingMovies { if let id = m.tmdbId { mDict[id] = m } }
        savedMoviesByID = mDict

        let existingShows = (try? modelContext.fetch(FetchDescriptor<TVShow>())) ?? []
        savedTVIDs = Set(existingShows.compactMap { $0.tmdbId })
        var tDict: [String: TVShow] = [:]
        for s in existingShows { if let id = s.tmdbId { tDict[id] = s } }
        savedTVShowsByID = tDict
    }
}

#Preview { SearchView() } 
