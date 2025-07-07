import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    // Search state
    @State private var searchQuery: String = ""
    @State private var movieResults: [TMDBMovieSearchResult] = []
    @State private var tvResults: [TMDBTVShowSearchResult] = []
    @State private var isSearching = false
    // Category filters
    private enum Category: String, CaseIterable, Identifiable {
        case movies = "Movies"
        case tv = "TV Shows"
        case books = "Books"
        case games = "Games"
        var id: Self { self }
    }
    // Set of currently enabled categories (all enabled by default)
    @State private var selectedCategories: Set<Category> = Set(Category.allCases)
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
    // Book search state
    @State private var bookResults: [AppleBookSearchResult] = []
    @State private var selectedAppleBook: AppleBookDetails?
    @State private var showingBookPreview = false
    // Saved books presentation & cache
    @State private var presentingSavedBook: Book?
    @State private var savedBookIDs: Set<String> = []
    @State private var savedBooksByID: [String: Book] = [:]
    // Game search state
    @State private var gameResults: [IGDBGameSearchResult] = []
    @State private var selectedIGDBGame: IGDBGameDetails?
    @State private var showingGamePreview = false
    @State private var presentingSavedGame: Game?
    @State private var savedGameIDs: Set<String> = []
    @State private var savedGamesByID: [String: Game] = [:]
    // Search mode (Media APIs or on-device Library)
    private enum Mode: String, CaseIterable, Identifiable {
        case media = "Media"
        case library = "Library"
        var id: Self { self }
    }
    // Current search mode
    @State private var selectedMode: Mode = .media
    // Local library search results
    @State private var ownedMovieResults: [Movie] = []
    @State private var ownedTVResults: [TVShow] = []
    @State private var ownedBookResults: [Book] = []
    @State private var ownedGameResults: [Game] = []

    var body: some View {
        NavigationStack {
            VStack {
                Picker("Source", selection: $selectedMode) {
                    ForEach(Mode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                Group {
                    let hasAnyResults: Bool = {
                        if selectedMode == .media {
                            return !movieResults.isEmpty || !tvResults.isEmpty || !bookResults.isEmpty || !gameResults.isEmpty
                        } else {
                            return !ownedMovieResults.isEmpty || !ownedTVResults.isEmpty || !ownedBookResults.isEmpty || !ownedGameResults.isEmpty
                        }
                    }()

                    if isSearching {
                        ProgressView(selectedMode == .media ? "Searching databases…" : "Searching library…")
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
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    if selectedCategories.contains(.movies) {
                                        if selectedMode == .media {
                                            ForEach(movieResults) { movieSearchResultRow($0, isSaved: savedMovieIDs.contains(String($0.id))) }
                                        } else {
                                            ForEach(ownedMovieResults) { libraryMovieRow($0) }
                                        }
                                    }
                                    if selectedCategories.contains(.tv) {
                                        if selectedMode == .media {
                                            ForEach(tvResults) { tvShowSearchResultRow($0, isSaved: savedTVIDs.contains(String($0.id))) }
                                        } else {
                                            ForEach(ownedTVResults) { libraryTVShowRow($0) }
                                        }
                                    }
                                    if selectedCategories.contains(.books) {
                                        if selectedMode == .media {
                                            ForEach(bookResults) { bookSearchResultRow($0, isSaved: savedBookIDs.contains(String($0.trackId))) }
                                        } else {
                                            ForEach(ownedBookResults) { libraryBookRow($0) }
                                        }
                                    }
                                    if selectedCategories.contains(.games) {
                                        if selectedMode == .media {
                                            ForEach(gameResults) { gameSearchResultRow($0, isSaved: savedGameIDs.contains(String($0.id))) }
                                        } else {
                                            ForEach(ownedGameResults) { libraryGameRow($0) }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    } else {
                        ContentUnavailableView("Search", systemImage: "magnifyingglass", description: Text(searchQuery.isEmpty ? "Start typing to search your media library…" : "Press enter to search…"))
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(Category.allCases) { cat in
                            Toggle(
                                isOn: Binding<Bool>(
                                    get: { selectedCategories.contains(cat) },
                                    set: { isOn in
                                        if isOn {
                                            selectedCategories.insert(cat)
                                        } else {
                                            selectedCategories.remove(cat)
                                        }
                                    })
                            ) {
                                Text(cat.rawValue)
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .navigationTitle("Search")
            .searchable(text: $searchQuery, prompt: "Search Media")
            .onSubmit(of: .search) {
                if selectedMode == .media {
                    Task { await performSearch() }
                } else {
                    performLocalSearch()
                }
            }
            .onChange(of: searchQuery) { _ in
                hasSearched = false
                movieResults = []
                tvResults = []
                bookResults = []
                gameResults = []
                ownedMovieResults = []
                ownedTVResults = []
                ownedBookResults = []
                ownedGameResults = []
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
            // Book Preview
            .sheet(isPresented: $showingBookPreview, onDismiss: refreshSavedCache) {
                if let details = selectedAppleBook {
                    NavigationStack { BookView(book: details.toBook(), isPreview: true) }
                }
            }
            // Game Preview
            .sheet(isPresented: $showingGamePreview, onDismiss: refreshSavedCache) {
                if let details = selectedIGDBGame {
                    NavigationStack { GameView(game: details.toGame(), isPreview: true) }
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
            // Saved Book sheet
            .sheet(item: $presentingSavedBook, onDismiss: refreshSavedCache) { bk in
                NavigationStack { BookView(book: bk) }
            }
            // Saved Game sheet
            .sheet(item: $presentingSavedGame, onDismiss: refreshSavedCache) { gm in
                NavigationStack { GameView(game: gm) }
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

    private func bookSearchResultRow(_ result: AppleBookSearchResult, isSaved: Bool) -> some View {
        Button(action: { selectBook(result, isSaved: isSaved) }) {
            searchRowThumbnail(url: result.coverURL, title: result.trackName ?? "Unknown Title", subtitle: subtitleBook(result), trailingIcon: isSaved ? "checkmark.circle.fill" : "chevron.right", iconColor: isSaved ? .green : .secondary)
        }
        .buttonStyle(.plain)
    }

    private func gameSearchResultRow(_ result: IGDBGameSearchResult, isSaved: Bool) -> some View {
        Button(action: { selectGame(result, isSaved: isSaved) }) {
            searchRowThumbnail(url: result.thumbnailURL, title: result.name ?? "Unknown Title", subtitle: subtitleGame(result), trailingIcon: isSaved ? "checkmark.circle.fill" : "chevron.right", iconColor: isSaved ? .green : .secondary)
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

    private func subtitleBook(_ result: AppleBookSearchResult) -> String {
        var parts: [String] = ["Book"]
        if let year = result.year { parts.append(String(year)) }
        return parts.joined(separator: " • ")
    }

    private func subtitleGame(_ result: IGDBGameSearchResult) -> String {
        var parts: [String] = ["Game"]
        if let date = result.releaseDate {
            parts.append(String(Calendar.current.component(.year, from: date)))
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
            async let books = AppleBooksAPIManager.shared.searchBooks(term: searchQuery)
            async let games = IGDBAPIManager.shared.searchGameResults(query: searchQuery)
            self.movieResults = try await movies
            self.tvResults = try await tvs
            self.bookResults = try await books
            self.gameResults = try await games

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

            let existingBooks = (try? modelContext.fetch(FetchDescriptor<Book>())) ?? []
            savedBookIDs = Set(existingBooks.compactMap { $0.appleBookId })
            var bookDict: [String: Book] = [:]
            for book in existingBooks { if let id = book.appleBookId { bookDict[id] = book } }
            savedBooksByID = bookDict

            let existingGames = (try? modelContext.fetch(FetchDescriptor<Game>())) ?? []
            savedGameIDs = Set(existingGames.compactMap { $0.igdbId })
            var gameDict: [String: Game] = [:]
            for gm in existingGames { if let id = gm.igdbId { gameDict[id] = gm } }
            savedGamesByID = gameDict

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

    private func selectBook(_ result: AppleBookSearchResult, isSaved: Bool) {
        let idStr = String(result.trackId)
        if let existing = savedBooksByID[idStr] {
            presentingSavedBook = existing
        } else {
            isLoadingMovieDetails = true // reuse loading indicator
            Task {
                do {
                    let details = try await AppleBooksAPIManager.shared.getBook(id: result.trackId)
                    await MainActor.run {
                        self.selectedAppleBook = details
                        self.isLoadingMovieDetails = false
                        self.showingBookPreview = true
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

    private func selectGame(_ result: IGDBGameSearchResult, isSaved: Bool) {
        let idStr = String(result.id)
        if let existing = savedGamesByID[idStr] {
            presentingSavedGame = existing
        } else {
            isLoadingMovieDetails = true
            Task {
                do {
                    let details = try await IGDBAPIManager.shared.getGame(id: result.id)
                    await MainActor.run {
                        self.selectedIGDBGame = details
                        self.isLoadingMovieDetails = false
                        self.showingGamePreview = true
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

        let existingBooks = (try? modelContext.fetch(FetchDescriptor<Book>())) ?? []
        savedBookIDs = Set(existingBooks.compactMap { $0.appleBookId })
        var bDict: [String: Book] = [:]
        for b in existingBooks { if let id = b.appleBookId { bDict[id] = b } }
        savedBooksByID = bDict

        let existingGames = (try? modelContext.fetch(FetchDescriptor<Game>())) ?? []
        savedGameIDs = Set(existingGames.compactMap { $0.igdbId })
        var gDict: [String: Game] = [:]
        for g in existingGames { if let id = g.igdbId { gDict[id] = g } }
        savedGamesByID = gDict
    }

    // MARK: – Library Helpers
    private func libraryMovieRow(_ movie: Movie) -> some View {
        Button(action: { presentingSavedMovie = movie }) {
            searchRowThumbnail(url: movie.thumbnailURL, title: movie.title, subtitle: subtitleOwnedMovie(movie), trailingIcon: "chevron.right", iconColor: .secondary)
        }
        .buttonStyle(.plain)
    }

    private func libraryTVShowRow(_ show: TVShow) -> some View {
        Button(action: { presentingSavedTVShow = show }) {
            searchRowThumbnail(url: show.thumbnailURL, title: show.name, subtitle: subtitleOwnedTV(show), trailingIcon: "chevron.right", iconColor: .secondary)
        }
        .buttonStyle(.plain)
    }

    private func libraryBookRow(_ book: Book) -> some View {
        Button(action: { presentingSavedBook = book }) {
            searchRowThumbnail(url: book.coverURL, title: book.title, subtitle: subtitleOwnedBook(book), trailingIcon: "chevron.right", iconColor: .secondary)
        }
        .buttonStyle(.plain)
    }

    private func libraryGameRow(_ game: Game) -> some View {
        Button(action: { presentingSavedGame = game }) {
            searchRowThumbnail(url: game.thumbnailURL, title: game.name, subtitle: subtitleOwnedGame(game), trailingIcon: "chevron.right", iconColor: .secondary)
        }
        .buttonStyle(.plain)
    }

    private func subtitleOwnedMovie(_ movie: Movie) -> String {
        var parts: [String] = ["Movie"]
        if let year = movie.year { parts.append(String(year)) }
        return parts.joined(separator: " • ")
    }

    private func subtitleOwnedTV(_ show: TVShow) -> String {
        var parts: [String] = ["TV Show"]
        if let year = show.year { parts.append(String(year)) }
        return parts.joined(separator: " • ")
    }

    private func subtitleOwnedBook(_ book: Book) -> String {
        var parts: [String] = ["Book"]
        if let year = book.year { parts.append(String(year)) }
        return parts.joined(separator: " • ")
    }

    private func subtitleOwnedGame(_ game: Game) -> String {
        var parts: [String] = ["Game"]
        if let year = game.year { parts.append(String(year)) }
        return parts.joined(separator: " • ")
    }

    // MARK: – Local Search
    private func performLocalSearch() {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSearching = true
        defer {
            isSearching = false
            hasSearched = true
        }

        if selectedCategories.contains(.movies) {
            let all = (try? modelContext.fetch(FetchDescriptor<Movie>())) ?? []
            ownedMovieResults = all.filter { $0.title.localizedCaseInsensitiveContains(trimmed) }
        } else {
            ownedMovieResults = []
        }

        if selectedCategories.contains(.tv) {
            let all = (try? modelContext.fetch(FetchDescriptor<TVShow>())) ?? []
            ownedTVResults = all.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
        } else {
            ownedTVResults = []
        }

        if selectedCategories.contains(.books) {
            let all = (try? modelContext.fetch(FetchDescriptor<Book>())) ?? []
            ownedBookResults = all.filter { $0.title.localizedCaseInsensitiveContains(trimmed) || $0.author.localizedCaseInsensitiveContains(trimmed) }
        } else {
            ownedBookResults = []
        }

        if selectedCategories.contains(.games) {
            let all = (try? modelContext.fetch(FetchDescriptor<Game>())) ?? []
            ownedGameResults = all.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
        } else {
            ownedGameResults = []
        }
    }
}

#Preview { SearchView() } 
