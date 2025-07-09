import Foundation

extension AppleBookDetails {
    /// Converts the Apple Books API details into a local `Book` model instance that can be persisted.
    func toBook() -> Book {
        let releaseDateValue: Date? = {
            guard let isoString = releaseDate else { return nil }
            return ISO8601DateFormatter().date(from: isoString)
        }()
        return Book(
            title: trackName ?? "",
            author: artistName ?? "",
            read: false,
            year: year,
            rating: nil,
            appleRating: averageUserRating.map { $0 * 2 },
            coverURLString: artworkUrl100,
            synopsis: description,
            releaseDate: releaseDateValue,
            appleBookId: String(trackId),
            genres: genreNames.isEmpty ? nil : genreNames
        )
    }
} 