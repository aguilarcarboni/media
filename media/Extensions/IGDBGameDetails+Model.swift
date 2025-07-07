import Foundation

extension IGDBGameDetails {
    /// Converts IGDB details into a local `Game` model instance ready for preview / saving.
    func toGame() -> Game {
        let releaseDateValue = releaseDate
        let yearValue: Int? = {
            guard let date = releaseDateValue else { return nil }
            return Calendar.current.component(.year, from: date)
        }()
        return Game(
            name: name ?? "",
            played: false,
            year: yearValue,
            rating: nil,
            igdbRating: nil,
            coverImageID: cover?.image_id,
            genres: genreNames.isEmpty ? nil : genreNames,
            platforms: platformNames.joined(separator: ", "),
            summary: summary,
            releaseDate: releaseDateValue,
            igdbId: String(id)
        )
    }
} 