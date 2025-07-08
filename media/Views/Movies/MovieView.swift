//
//  MovieView.swift
//  media
//
//  Created by Andrés on 28/6/2025.
//

import SwiftUI
import SwiftData

struct MovieView: View {
    @Bindable var movie: Movie
    // Indicates whether this view is showing a temporary preview of a movie not yet saved to the library.
    var isPreview: Bool = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    // Rating sheet state
    @State private var showingRatingSheet: Bool = false
    @State private var tempRating: Double
    @State private var showingDeleteAlert: Bool = false
    
    init(movie: Movie, isPreview: Bool = false) {
        // Initialize @Bindable property manually
        self._movie = Bindable(wrappedValue: movie)
        self.isPreview = isPreview
        // Start rating at personal rating if available, then TMDB rating, else 0.5
        _tempRating = State(initialValue: movie.rating ?? movie.tmdbRating ?? 0.5)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                HStack(alignment: .top, spacing: 16) {
                    // Movie details
                    VStack(alignment: .leading, spacing: 12) {
                        
                        // Quick details
                        VStack(alignment: .leading, spacing: 6) {
                            if let runtime = movie.runtime {
                                Label("\(runtime) minutes", systemImage: "clock")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            if !movie.genreList.isEmpty {
                                Label(movie.genreList.joined(separator: ", "), systemImage: "tag")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            if let releaseDate = movie.releaseDateFormatted {
                                Label {
                                    Text(releaseDate, format: .dateTime.day().month().year())
                                } icon: {
                                    Image(systemName: "calendar")
                                }
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }

                            if movie.rating != nil {
                                Label {
                                    Text("Personal: \(movie.rating! * 10, specifier: "%.0f%%")")
                                } icon: {
                                    Image(systemName: "star.circle.fill")
                                }
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }

                            if movie.tmdbRating != nil {
                                Label {
                                    Text("TMDB: \(movie.tmdbRating! * 10, specifier: "%.0f%%")")
                                } icon: {
                                    Image(systemName: "star.circle.fill")
                                }
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }

                            if !movie.directorList.isEmpty {
                                Label {
                                     Text("Directors: \(movie.directorList.joined(separator: ", "))")
                                } icon: {
                                    Image(systemName: "person.2.fill")
                                }
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            } 
                        }
                        
                        Spacer()
                    }

                    Spacer()

                    // Poster
                    AsyncImage(url: movie.posterURL) { image in
                        image
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
                
                // Overview
                if let overview = movie.overview, !overview.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Overview")
                            .font(.headline)
                        Text(overview)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                // Cast and Crew
                if !movie.castList.isEmpty || !movie.directorList.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Cast & Crew")
                            .font(.headline)
                        
                        if !movie.directorList.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Directors")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(movie.directorList.joined(separator: ", "))
                                    .font(.body)
                            }
                        }
                        
                        if !movie.castList.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Cast")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(movie.castList.joined(separator: ", "))
                                    .font(.body)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            
                // Backdrop
                ZStack(alignment: .bottomLeading) {
                    // Backdrop image
                    AsyncImage(url: movie.backdropURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
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
                }
            }
            .padding()
        }
        .toolbar {
            if isPreview {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) { Image(systemName: "xmark") }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        modelContext.insert(movie)
                        dismiss()
                    }) { Image(systemName: "plus") }
                }
            } else {
                // Delete movie toolbar button
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .tint(.red)
                }
                ToolbarItem() {
                    Button {
                        if movie.watched {
                            movie.markAsUnwatched()
                        } else {
                            movie.markAsWatched()
                        }
                    } label: {
                        Image(systemName: movie.watched ? "checkmark.circle.fill" : "circle")
                    }
                }
                if movie.watched {
                    // Rating menu toolbar item
                    ToolbarItem {
                        Menu {
                            Stepper(value: $tempRating, in: 0...10, step: 0.1) {
                                Text(String(format: "%.0f%%",tempRating * 10))
                            }
                            Button("Save") {
                                movie.rating = tempRating
                                movie.updated = Date()
                            }
                        } label: {
                            Image(systemName: movie.rating != nil ? "star.circle.fill" : "star.circle")
                        }
                    }
                }
                ToolbarItem() {
                    Menu {
                        if movie.tmdbId != nil {
                            Button("Refresh from TMDB") {
                                refreshFromTMDB()
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }
        }
        // Rating sheet
        .sheet(isPresented: $showingRatingSheet) {
            NavigationStack {
                Form {
                    Section("Your Rating") {
                        Slider(value: $tempRating, in: 0...10, step: 0.1)
                        HStack {
                            Spacer()
                            Text(String(format: "%.1f (%.0f%%)", tempRating, tempRating * 10))
                                .font(.title2)
                            Spacer()
                        }
                    }
                }
                .navigationTitle("Rate Movie")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(action: {
                            showingRatingSheet = false
                        }) {
                            Image(systemName: "xmark")
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(action: {
                            movie.rating = tempRating
                            movie.updated = Date()
                            showingRatingSheet = false
                        }) {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }
        // Delete confirmation alert
        .alert("Delete Movie?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                // Close rating sheet (if open) then delete and dismiss this view
                showingRatingSheet = false
                modelContext.delete(movie)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    private func refreshFromTMDB() {
        guard let tmdbIdString = movie.tmdbId,
              let tmdbId = Int(tmdbIdString) else { return }
        
        Task {
            do {
                let tmdbMovie = try await TMDBAPIManager.shared.getMovie(id: tmdbId)
                await MainActor.run {
                    movie.updateFromTMDB(tmdbMovie)
                }
            } catch {
                print("Failed to refresh from TMDB: \(error)")
            }
        }
    }
} 

