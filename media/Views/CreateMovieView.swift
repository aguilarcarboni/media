//
//  CreateMovieView.swift
//  media
//
//  Created by Andrés on 28/6/2025.
//

import SwiftUI
import SwiftData

struct CreateMovieView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab = 0
    @State private var showingPreview = false
    
    // Movie data
    @State private var title = ""
    @State private var year = ""
    @State private var genre = ""
    @State private var rating = ""
    @State private var runtime = ""
    @State private var overview = ""
    
    // TMDB Integration
    @State private var searchQuery = ""
    @State private var searchResults: [TMDBMovieSearchResult] = []
    @State private var isSearching = false
    @State private var selectedTMDBMovie: TMDBMovieDetails?
    @State private var isLoadingMovieDetails = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            if showingPreview {
                previewView
            } else {
                mainView
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var mainView: some View {
        TabView(selection: $selectedTab) {
            manualEntryTab
                .tabItem {
                    Label("Manual Entry", systemImage: "pencil")
                }
                .tag(0)
            
            tmdbSearchTab
                .tabItem {
                    Label("Search TMDB", systemImage: "magnifyingglass")
                }
                .tag(1)
        }
        .navigationTitle("Add Movie")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
    
    private var manualEntryTab: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                TextField("Movie Title", text: $title)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)
                
                HStack(spacing: 12) {
                    TextField("Year", text: $year)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Runtime (min)", text: $runtime)
                        .textFieldStyle(.roundedBorder)
                }
                
                HStack(spacing: 12) {
                    TextField("Genre", text: $genre)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Rating (0-10)", text: $rating)
                        .textFieldStyle(.roundedBorder)
                }
                
                TextField("Overview or notes", text: $overview, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(4...8)
            }
            
            Spacer()
            
            Button(action: {
                showingPreview = true
            }) {
                Text("Continue to Preview")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.accentColor)
                    .cornerRadius(12)
            }
            .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
    }
    
    private var tmdbSearchTab: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                HStack {
                    TextField("Search for a movie...", text: $searchQuery)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            searchMovies()
                        }
                    
                    Button(action: searchMovies) {
                        if isSearching {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .disabled(isSearching || searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .buttonStyle(.bordered)
                }
                
                if isSearching {
                    ProgressView("Searching TMDB...")
                        .padding()
                }
            }
            
            if !searchResults.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(searchResults.prefix(10)) { result in
                            movieSearchResultRow(result)
                        }
                    }
                    .padding(.horizontal)
                }
            } else if !searchQuery.isEmpty && !isSearching {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    
                    Text("No results found")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text("Try a different search term")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func movieSearchResultRow(_ result: TMDBMovieSearchResult) -> some View {
        Button(action: {
            selectMovie(result)
        }) {
            HStack(spacing: 12) {
                AsyncImage(url: result.thumbnailURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(.secondary.opacity(0.2))
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        }
                }
                .frame(width: 50, height: 75)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    
                    if let year = result.year {
                        Text("\(year)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let overview = result.overview {
                        Text(overview)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
                
                if isLoadingMovieDetails {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
    
    private var previewView: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Text("Preview")
                        .font(.largeTitle)
                        .bold()
                    
                    Text("Review your movie details before adding")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                VStack(spacing: 16) {
                    previewRow("Title", value: title)
                    
                    HStack {
                        previewRow("Year", value: year.isEmpty ? "Unknown" : year)
                        Spacer()
                        previewRow("Runtime", value: runtime.isEmpty ? "Unknown" : "\(runtime) min")
                    }
                    
                    HStack {
                        previewRow("Genre", value: genre.isEmpty ? "Unknown" : genre)
                        Spacer()
                        previewRow("Rating", value: rating.isEmpty ? "Unrated" : "\(rating)/10")
                    }
                    
                    if !overview.isEmpty {
                        previewRow("Overview", value: overview, isLong: true)
                    }
                    
                    if selectedTMDBMovie != nil {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Imported from TMDB")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                    }
                }
                .padding()
                .cornerRadius(16)
                
                VStack(spacing: 12) {
                    Button(action: addMovie) {
                        Text("Add Movie")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        showingPreview = false
                    }) {
                        Text("Back to Edit")
                            .font(.headline)
                            .foregroundColor(.accentColor)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Add Movie")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
    
    private func previewRow(_ label: String, value: String, isLong: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            
            Text(value)
                .font(isLong ? .body : .headline)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func searchMovies() {
        guard !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { 
            return 
        }
        
        isSearching = true
        searchResults = []
        
        Task {
            do {
                let results = try await TMDBAPIManager.shared.searchMovieResults(query: searchQuery)
                
                await MainActor.run {
                    self.searchResults = results
                    self.isSearching = false
                }
            } catch {
                await MainActor.run {
                    self.isSearching = false
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                }
            }
        }
    }
    
    private func selectMovie(_ searchResult: TMDBMovieSearchResult) {
        isLoadingMovieDetails = true
        
        Task {
            do {
                let movieDetails = try await TMDBAPIManager.shared.getMovie(id: searchResult.id)
                await MainActor.run {
                    populateFields(with: movieDetails)
                    self.selectedTMDBMovie = movieDetails
                    self.isLoadingMovieDetails = false
                    self.searchResults = []
                    self.searchQuery = ""
                    self.showingPreview = true
                }
            } catch {
                await MainActor.run {
                    self.isLoadingMovieDetails = false
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                }
            }
        }
    }
    
    private func populateFields(with movie: TMDBMovieDetails) {
        title = movie.title
        year = movie.year.map(String.init) ?? ""
        genre = movie.genreNames
        rating = String(format: "%.1f", movie.voteAverage)
        runtime = movie.runtime.map(String.init) ?? ""
        overview = movie.overview ?? ""
    }
    
    private func addMovie() {
        let newMovie: Movie
        
        if let tmdbMovie = selectedTMDBMovie {
            // Create movie from TMDB data
            newMovie = tmdbMovie.toMovie()
            // Override with any manual edits
            newMovie.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            if let yearInt = Int(year.trimmingCharacters(in: .whitespacesAndNewlines)) {
                newMovie.year = yearInt
            }
            if let ratingDouble = Double(rating.trimmingCharacters(in: .whitespacesAndNewlines)) {
                newMovie.rating = ratingDouble
            }
            if let runtimeInt = Int(runtime.trimmingCharacters(in: .whitespacesAndNewlines)) {
                newMovie.runtime = runtimeInt
            }
            let genreText = genre.trimmingCharacters(in: .whitespacesAndNewlines)
            newMovie.genres = genreText.isEmpty ? nil : genreText
            let overviewText = overview.trimmingCharacters(in: .whitespacesAndNewlines)
            newMovie.overview = overviewText.isEmpty ? nil : overviewText
        } else {
            // Create movie manually
            newMovie = Movie(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                year: Int(year.trimmingCharacters(in: .whitespacesAndNewlines)),
                rating: Double(rating.trimmingCharacters(in: .whitespacesAndNewlines)),
                runtime: Int(runtime.trimmingCharacters(in: .whitespacesAndNewlines)),
                genres: genre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : genre.trimmingCharacters(in: .whitespacesAndNewlines),
                overview: overview.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : overview.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
        
        modelContext.insert(newMovie)
        dismiss()
    }
} 
