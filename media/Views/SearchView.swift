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
        case comics = "Comic Volumes"
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
    // Comic (Volume) search state
    @State private var volumeResults: [ComicVineVolumeSearchResult] = []
    @State private var selectedVolumeDetails: ComicVineVolumeDetails?
    @State private var showingVolumePreview = false
    @State private var presentingSavedVolume: Volume?
    @State private var savedVolumeIDs: Set<String> = []
    @State private var savedVolumesByID: [String: Volume] = [:]

    // Game search state
    @State private var gameResults: [IGDBGameSearchResult] = []
    @State private var selectedIGDBGame: IGDBGameDetails?
    @State private var showingGamePreview = false
    @State private var presentingSavedGame: Game?
    @State private var savedGameIDs: Set<String> = []
    @State private var savedGamesByID: [String: Game] = [:]
    // Owned volumes results for library search
    @State private var ownedVolumeResults: [Volume] = []

    // MARK: – Unified result wrappers
    private enum MediaItem: Identifiable {
        case movie(TMDBMovieSearchResult)
        case tv(TMDBTVShowSearchResult)
        case book(AppleBookSearchResult)
        case game(IGDBGameSearchResult)
        case volume(ComicVineVolumeSearchResult)

        var id: String {
            switch self {
            case .movie(let m): return "movie_\(m.id)"
            case .tv(let s): return "tv_\(s.id)"
            case .book(let b): return "book_\(b.trackId)"
            case .game(let g): return "game_\(g.id)"
            case .volume(let v): return "volume_\(v.id)"
            }
        }

        var titleForScoring: String {
            switch self {
            case .movie(let m): return m.title
            case .tv(let s): return s.name
            case .book(let b): return b.trackName ?? ""
            case .game(let g): return g.name ?? ""
            case .volume(let v): return v.title
            }
        }
    }

    private enum LibraryItem: Identifiable {
        case movie(Movie)
        case tv(TVShow)
        case book(Book)
        case game(Game)
        case volume(Volume)

        var id: String {
            switch self {
            case .movie(let m): return "movie_\(m.id.uuidString)"
            case .tv(let s): return "tv_\(s.id.uuidString)"
            case .book(let b): return "book_\(b.id.uuidString)"
            case .game(let g): return "game_\(g.id.uuidString)"
            case .volume(let v): return "volume_\(v.id.uuidString)"
            }
        }

        var titleForScoring: String {
            switch self {
            case .movie(let m): return m.title
            case .tv(let s): return s.name
            case .book(let b): return b.title
            case .game(let g): return g.name
            case .volume(let v): return v.name
            }
        }
    }

    private var mixedMediaResults: [MediaItem] {
        var items: [MediaItem] = []
        if selectedCategories.contains(.movies) { items.append(contentsOf: movieResults.map(MediaItem.movie)) }
        if selectedCategories.contains(.tv) { items.append(contentsOf: tvResults.map(MediaItem.tv)) }
        if selectedCategories.contains(.books) { items.append(contentsOf: bookResults.map(MediaItem.book)) }
        if selectedCategories.contains(.comics) { items.append(contentsOf: volumeResults.map(MediaItem.volume)) }
        if selectedCategories.contains(.games) { items.append(contentsOf: gameResults.map(MediaItem.game)) }

        return items.sorted { $0.titleForScoring.relevanceScore(to: searchQuery) > $1.titleForScoring.relevanceScore(to: searchQuery) }
    }

    private var mixedLibraryResults: [LibraryItem] {
        var items: [LibraryItem] = []
        if selectedCategories.contains(.movies) { items.append(contentsOf: ownedMovieResults.map(LibraryItem.movie)) }
        if selectedCategories.contains(.tv) { items.append(contentsOf: ownedTVResults.map(LibraryItem.tv)) }
        if selectedCategories.contains(.books) { items.append(contentsOf: ownedBookResults.map(LibraryItem.book)) }
        if selectedCategories.contains(.comics) { items.append(contentsOf: ownedVolumeResults.map(LibraryItem.volume)) }
        if selectedCategories.contains(.games) { items.append(contentsOf: ownedGameResults.map(LibraryItem.game)) }

        return items.sorted { $0.titleForScoring.relevanceScore(to: searchQuery) > $1.titleForScoring.relevanceScore(to: searchQuery) }
    }

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

    // Computed: Order categories by top match score
    private var orderedCategories: [Category] {
        let q = searchQuery
        func topScore(for cat: Category) -> Int {
            switch cat {
            case .movies:
                return (selectedMode == .media ? movieResults.first?.title : ownedMovieResults.first?.title)?.relevanceScore(to: q) ?? Int.min
            case .tv:
                return (selectedMode == .media ? tvResults.first?.name : ownedTVResults.first?.name)?.relevanceScore(to: q) ?? Int.min
            case .books:
                return (selectedMode == .media ? bookResults.first?.trackName : ownedBookResults.first?.title)?.relevanceScore(to: q) ?? Int.min
            case .comics:
                return (selectedMode == .media ? volumeResults.first?.title : ownedVolumeResults.first?.name)?.relevanceScore(to: q) ?? Int.min
            case .games:
                return (selectedMode == .media ? gameResults.first?.name : ownedGameResults.first?.name)?.relevanceScore(to: q) ?? Int.min
            }
        }

        // Convert the selected set to an array, sort by descending score
        return selectedCategories.sorted { topScore(for: $0) > topScore(for: $1) }
    }

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Picker("Source", selection: $selectedMode) {
                        ForEach(Mode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    Spacer(minLength: 8)

                    // Category filter menu now lives next to the picker instead of the (broken) toolbar
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
                            .imageScale(.large)
                    }
                }
                .padding(.horizontal)

                Group {
                    let hasAnyResults: Bool = {
                        if selectedMode == .media {
                            return !movieResults.isEmpty || !tvResults.isEmpty || !bookResults.isEmpty || !gameResults.isEmpty || !volumeResults.isEmpty
                        } else {
                            return !ownedMovieResults.isEmpty || !ownedTVResults.isEmpty || !ownedBookResults.isEmpty || !ownedGameResults.isEmpty || !ownedVolumeResults.isEmpty
                        }
                    }()

                    if isSearching {
                        Spacer()
                        ProgressView(selectedMode == .media ? "Searching..." : "Searching library...")
                        Spacer()
                    } else if hasSearched {
                        if !hasAnyResults {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.secondary)
                                Text("No results for \"\(searchQuery)\"")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    if selectedMode == .media {
                                        ForEach(mixedMediaResults) { item in
                                            mediaRow(for: item)
                                        }
                                    } else {
                                        ForEach(mixedLibraryResults) { item in
                                            libraryRow(for: item)
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
            // Removed broken toolbar filter – now integrated next to the picker
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
                volumeResults = []
                ownedMovieResults = []
                ownedTVResults = []
                ownedBookResults = []
                ownedGameResults = []
                ownedVolumeResults = []
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
            // Volume Preview
            .sheet(isPresented: $showingVolumePreview, onDismiss: refreshSavedCache) {
                if let details = selectedVolumeDetails {
                    NavigationStack { VolumeView(volume: details.toVolume(), isPreview: true) }
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
            // Saved Volume sheet
            .sheet(item: $presentingSavedVolume, onDismiss: refreshSavedCache) { vol in
                NavigationStack { VolumeView(volume: vol) }
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
            async let volumes = ComicVineAPIManager.shared.searchVolumes(query: searchQuery)

            let unsortedMovies = try await movies
            let unsortedTVs = try await tvs
            let unsortedBooks = try await books
            let unsortedGames = try await games
            let unsortedVolumes = try await volumes

            self.movieResults = unsortedMovies.sorted { $0.title.relevanceScore(to: searchQuery) > $1.title.relevanceScore(to: searchQuery) }
            self.tvResults = unsortedTVs.sorted { $0.name.relevanceScore(to: searchQuery) > $1.name.relevanceScore(to: searchQuery) }
            self.bookResults = unsortedBooks.sorted { ($0.trackName ?? "").relevanceScore(to: searchQuery) > ($1.trackName ?? "").relevanceScore(to: searchQuery) }
            self.gameResults = unsortedGames.sorted { ($0.name ?? "").relevanceScore(to: searchQuery) > ($1.name ?? "").relevanceScore(to: searchQuery) }
            self.volumeResults = unsortedVolumes.sorted { $0.title.relevanceScore(to: searchQuery) > $1.title.relevanceScore(to: searchQuery) }

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

            let existingVolumes = (try? modelContext.fetch(FetchDescriptor<Volume>())) ?? []
            savedVolumeIDs = Set(existingVolumes.compactMap { $0.comicVineId.map(String.init) })
            var volDict: [String: Volume] = [:]
            for v in existingVolumes { if let id = v.comicVineId { volDict[String(id)] = v } }
            savedVolumesByID = volDict

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

    private func selectVolume(_ result: ComicVineVolumeSearchResult, isSaved: Bool) {
        let idStr = String(result.id)
        if let existing = savedVolumesByID[idStr] {
            presentingSavedVolume = existing
        } else {
            isLoadingMovieDetails = true
            Task {
                do {
                    let details = try await ComicVineAPIManager.shared.getVolume(id: result.id)
                    await MainActor.run {
                        self.selectedVolumeDetails = details
                        self.isLoadingMovieDetails = false
                        self.showingVolumePreview = true
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

        let existingVolumes = (try? modelContext.fetch(FetchDescriptor<Volume>())) ?? []
        savedVolumeIDs = Set(existingVolumes.compactMap { $0.comicVineId.map(String.init) })
        var vDict: [String: Volume] = [:]
        for v in existingVolumes { if let id = v.comicVineId { vDict[String(id)] = v } }
        savedVolumesByID = vDict
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
                .sorted { $0.title.relevanceScore(to: trimmed) > $1.title.relevanceScore(to: trimmed) }
        } else {
            ownedMovieResults = []
        }

        if selectedCategories.contains(.tv) {
            let all = (try? modelContext.fetch(FetchDescriptor<TVShow>())) ?? []
            ownedTVResults = all.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
                .sorted { $0.name.relevanceScore(to: trimmed) > $1.name.relevanceScore(to: trimmed) }
        } else {
            ownedTVResults = []
        }

        if selectedCategories.contains(.books) {
            let all = (try? modelContext.fetch(FetchDescriptor<Book>())) ?? []
            ownedBookResults = all.filter { $0.title.localizedCaseInsensitiveContains(trimmed) || $0.author.localizedCaseInsensitiveContains(trimmed) }
                .sorted { $0.title.relevanceScore(to: trimmed) > $1.title.relevanceScore(to: trimmed) }
        } else {
            ownedBookResults = []
        }

        if selectedCategories.contains(.comics) {
            let all = (try? modelContext.fetch(FetchDescriptor<Volume>())) ?? []
            ownedVolumeResults = all.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
                .sorted { $0.name.relevanceScore(to: trimmed) > $1.name.relevanceScore(to: trimmed) }
        } else {
            ownedVolumeResults = []
        }

        if selectedCategories.contains(.games) {
            let all = (try? modelContext.fetch(FetchDescriptor<Game>())) ?? []
            ownedGameResults = all.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
                .sorted { $0.name.relevanceScore(to: trimmed) > $1.name.relevanceScore(to: trimmed) }
        } else {
            ownedGameResults = []
        }

        // ensure ownedVolumeResults cleared if not needed above
    }

    // MARK: – Volume Rows
    private func volumeSearchResultRow(_ result: ComicVineVolumeSearchResult, isSaved: Bool) -> some View {
        Button(action: { selectVolume(result, isSaved: isSaved) }) {
            searchRowThumbnail(url: result.thumbnailURL, title: result.title, subtitle: subtitleVolume(result), trailingIcon: isSaved ? "checkmark.circle.fill" : "chevron.right", iconColor: isSaved ? .green : .secondary)
        }.buttonStyle(.plain)
    }

    private func libraryVolumeRow(_ volume: Volume) -> some View {
        Button(action: { presentingSavedVolume = volume }) {
            searchRowThumbnail(url: volume.thumbnailURL, title: volume.name, subtitle: subtitleOwnedVolume(volume), trailingIcon: "chevron.right", iconColor: .secondary)
        }.buttonStyle(.plain)
    }

    private func subtitleVolume(_ result: ComicVineVolumeSearchResult) -> String {
        var parts: [String] = ["Comic Volume"]
        if let year = result.startYear { parts.append(String(year)) }
        return parts.joined(separator: " • ")
    }

    private func subtitleOwnedVolume(_ volume: Volume) -> String {
        var parts: [String] = ["Comic Volume"]
        if let year = volume.startYear { parts.append(String(year)) }
        return parts.joined(separator: " • ")
    }

    // MARK: – Row builders for unified lists
    @ViewBuilder private func mediaRow(for item: MediaItem) -> some View {
        switch item {
        case .movie(let res): movieSearchResultRow(res, isSaved: savedMovieIDs.contains(String(res.id)))
        case .tv(let res): tvShowSearchResultRow(res, isSaved: savedTVIDs.contains(String(res.id)))
        case .book(let res): bookSearchResultRow(res, isSaved: savedBookIDs.contains(String(res.trackId)))
        case .game(let res): gameSearchResultRow(res, isSaved: savedGameIDs.contains(String(res.id)))
        case .volume(let res): volumeSearchResultRow(res, isSaved: savedVolumeIDs.contains(String(res.id)))
        }
    }

    @ViewBuilder private func libraryRow(for item: LibraryItem) -> some View {
        switch item {
        case .movie(let m): libraryMovieRow(m)
        case .tv(let t): libraryTVShowRow(t)
        case .book(let b): libraryBookRow(b)
        case .game(let g): libraryGameRow(g)
        case .volume(let v): libraryVolumeRow(v)
        }
    }
}

#Preview { SearchView() } 
