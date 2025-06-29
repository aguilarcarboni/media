//
//  CSVImportView.swift
//  media
//
//  Created by Andrés on 28/6/2025.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct CSVImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var isImporting = false
    @State private var showingFilePicker = false
    @State private var importResult: ImportResult?
    @State private var selectedFileURL: URL?
    
    enum ImportResult {
        case success(count: Int)
        case error(message: String)
        
        var isSuccess: Bool {
            if case .success = self {
                return true
            }
            return false
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header section
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.blue)
                        
                        VStack(spacing: 8) {
                            Text("Import CSV File")
                                .font(.title2)
                                .bold()
                            
                            Text("Select a CSV file to import movies")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    // CSV structure info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Required CSV Structure:")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 4))
                                    .foregroundStyle(.secondary)
                                Text("title (string) - Required")
                            }
                            HStack {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 4))
                                    .foregroundStyle(.secondary)
                                Text("watched (true/false) - Required")
                            }
                            HStack {
                                Image(systemName: "circle")
                                    .font(.system(size: 4))
                                    .foregroundStyle(.secondary)
                                Text("year (number) - Optional")
                            }
                            HStack {
                                Image(systemName: "circle")
                                    .font(.system(size: 4))
                                    .foregroundStyle(.secondary)
                                Text("rating (number) - Optional (user rating)")
                            }
                            HStack {
                                Image(systemName: "circle")
                                    .font(.system(size: 4))
                                    .foregroundStyle(.secondary)
                                Text("tmdbRating (number) - Optional (TMDB rating)")
                            }
                            HStack {
                                Image(systemName: "circle")
                                    .font(.system(size: 4))
                                    .foregroundStyle(.secondary)
                                Text("genres (string) - Optional (comma-separated)")
                            }
                            HStack {
                                Image(systemName: "circle")
                                    .font(.system(size: 4))
                                    .foregroundStyle(.secondary)
                                Text("runtime (number) - Optional (minutes)")
                            }
                            HStack {
                                Image(systemName: "circle")
                                    .font(.system(size: 4))
                                    .foregroundStyle(.secondary)
                                Text("overview (string) - Optional")
                            }
                            HStack {
                                Image(systemName: "circle")
                                    .font(.system(size: 4))
                                    .foregroundStyle(.secondary)
                                Text("posterPath (string) - Optional (TMDB path)")
                            }
                            HStack {
                                Image(systemName: "circle")
                                    .font(.system(size: 4))
                                    .foregroundStyle(.secondary)
                                Text("backdropPath (string) - Optional (TMDB path)")
                            }
                            HStack {
                                Image(systemName: "circle")
                                    .font(.system(size: 4))
                                    .foregroundStyle(.secondary)
                                Text("releaseDate (string) - Optional (yyyy-MM-dd)")
                            }
                            HStack {
                                Image(systemName: "circle")
                                    .font(.system(size: 4))
                                    .foregroundStyle(.secondary)
                                Text("tmdbId (string) - Optional")
                            }
                            HStack {
                                Image(systemName: "circle")
                                    .font(.system(size: 4))
                                    .foregroundStyle(.secondary)
                                Text("directors (string) - Optional (comma-separated)")
                            }
                            HStack {
                                Image(systemName: "circle")
                                    .font(.system(size: 4))
                                    .foregroundStyle(.secondary)
                                Text("cast (string) - Optional (comma-separated)")
                            }
                        }
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        
                        Text("Note: Legacy fields 'genre' and 'poster' are still supported for backward compatibility.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .italic()
                    }
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(12)
                    
                    // Selected file section
                    if let selectedFileURL {
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "doc.fill")
                                    .foregroundStyle(.blue)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Selected File:")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(selectedFileURL.lastPathComponent)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                }
                                Spacer()
                            }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Import result section
                    if let result = importResult {
                        Group {
                            switch result {
                            case .success(let count):
                                VStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.green)
                                    Text("Successfully imported \(count) movies!")
                                        .font(.headline)
                                        .foregroundStyle(.green)
                                }
                            case .error(let message):
                                VStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.red)
                                    Text("Import Failed")
                                        .font(.headline)
                                        .foregroundStyle(.red)
                                    Text(message)
                                        .font(.body)
                                        .multilineTextAlignment(.center)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(result.isSuccess ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            showingFilePicker = true
                        }) {
                            HStack {
                                Image(systemName: "folder")
                                Text("Select CSV File")
                            }
                            .frame(minWidth: 200)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isImporting)
                        
                        if selectedFileURL != nil {
                            Button(action: {
                                importCSV()
                            }) {
                                HStack {
                                    if isImporting {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        Text("Importing...")
                                    } else {
                                        Image(systemName: "square.and.arrow.down")
                                        Text("Import")
                                    }
                                }
                                .frame(minWidth: 200)
                            }
                            .buttonStyle(.bordered)
                            .disabled(isImporting || selectedFileURL == nil)
                        }
                        
                        if case .success = importResult {
                            Button("Done") {
                                dismiss()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .padding(24)
            }
            .frame(maxWidth: 500, maxHeight: .infinity)
            .frame(minWidth: 480, minHeight: 400)
            .navigationTitle("Import CSV")
            .navigationBarBackButtonHidden(isImporting)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isImporting)
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.commaSeparatedText, .plainText],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        selectedFileURL = url
                        importResult = nil
                    }
                case .failure(let error):
                    importResult = .error(message: "Failed to select file: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func importCSV() {
        guard let fileURL = selectedFileURL else { return }
        
        isImporting = true
        importResult = nil
        
        Task {
            do {
                // Start accessing the security-scoped resource
                let accessing = fileURL.startAccessingSecurityScopedResource()
                defer {
                    if accessing {
                        fileURL.stopAccessingSecurityScopedResource()
                    }
                }
                
                let csvData = try String(contentsOf: fileURL, encoding: .utf8)
                let movies = try parseCSV(csvData)
                
                await MainActor.run {
                    // Add movies to model context
                    for movie in movies {
                        modelContext.insert(movie)
                    }
                    
                    try? modelContext.save()
                    importResult = .success(count: movies.count)
                    isImporting = false
                }
            } catch {
                await MainActor.run {
                    importResult = .error(message: error.localizedDescription)
                    isImporting = false
                }
            }
        }
    }
    
    private func parseCSV(_ csvContent: String) throws -> [Movie] {
        let lines = csvContent.components(separatedBy: .newlines)
        guard !lines.isEmpty else {
            throw CSVImportError.emptyFile
        }
        
        // Remove empty lines
        let nonEmptyLines = lines.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard nonEmptyLines.count >= 2 else {
            throw CSVImportError.insufficientData
        }
        
        // Parse header
        let header = parseCSVLine(nonEmptyLines[0])
        try validateHeader(header)
        
        // Create column mapping
        let columnMapping = createColumnMapping(header)
        
        var movies: [Movie] = []
        
        for lineIndex in 1..<nonEmptyLines.count {
            let line = nonEmptyLines[lineIndex]
            let columns = parseCSVLine(line)
            
            guard columns.count == header.count else {
                throw CSVImportError.inconsistentColumns(line: lineIndex + 1)
            }
            
            do {
                let movie = try createMovie(from: columns, using: columnMapping)
                movies.append(movie)
            } catch {
                throw CSVImportError.invalidData(line: lineIndex + 1, error: error.localizedDescription)
            }
        }
        
        return movies
    }
    
    private func parseCSVLine(_ line: String) -> [String] {
        var columns: [String] = []
        var currentColumn = ""
        var inQuotes = false
        var i = line.startIndex
        
        while i < line.endIndex {
            let char = line[i]
            
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                columns.append(currentColumn.trimmingCharacters(in: .whitespaces))
                currentColumn = ""
            } else {
                currentColumn.append(char)
            }
            
            i = line.index(after: i)
        }
        
        columns.append(currentColumn.trimmingCharacters(in: .whitespaces))
        return columns
    }
    
    private func validateHeader(_ header: [String]) throws {
        let requiredColumns = ["title", "watched"]
        let optionalColumns = [
            "year", "rating", "tmdbRating", "genres", "runtime", "overview", 
            "posterPath", "backdropPath", "releaseDate", "tmdbId", "directors", "cast",
            // Legacy support
            "genre", "poster"
        ]
        let allowedColumns = requiredColumns + optionalColumns
        
        // Check for required columns
        for required in requiredColumns {
            if !header.contains(where: { $0.lowercased() == required.lowercased() }) {
                throw CSVImportError.missingRequiredColumn(required)
            }
        }
        
        // Check for unknown columns
        for column in header {
            if !allowedColumns.contains(where: { $0.lowercased() == column.lowercased() }) {
                throw CSVImportError.unknownColumn(column)
            }
        }
    }
    
    private func createColumnMapping(_ header: [String]) -> [String: Int] {
        var mapping: [String: Int] = [:]
        for (index, column) in header.enumerated() {
            mapping[column.lowercased()] = index
        }
        return mapping
    }
    
    private func safeStringValue(from columns: [String], at index: Int?) -> String? {
        guard let index = index, index < columns.count else { return nil }
        let value = columns[index].trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
    
    private func safeIntValue(from columns: [String], at index: Int?) -> Int? {
        guard let stringValue = safeStringValue(from: columns, at: index) else { return nil }
        return Int(stringValue)
    }
    
    private func safeDoubleValue(from columns: [String], at index: Int?) -> Double? {
        guard let stringValue = safeStringValue(from: columns, at: index) else { return nil }
        return Double(stringValue)
    }
    
    private func createMovie(from columns: [String], using mapping: [String: Int]) throws -> Movie {
        guard let titleIndex = mapping["title"],
              let watchedIndex = mapping["watched"] else {
            throw CSVImportError.missingRequiredColumn("title or watched")
        }
        
        let title = columns[titleIndex].trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            throw CSVImportError.emptyRequiredField("title")
        }
        
        let watchedString = columns[watchedIndex].lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let watched: Bool
        switch watchedString {
        case "true", "yes", "1":
            watched = true
        case "false", "no", "0", "":
            watched = false
        default:
            throw CSVImportError.invalidBooleanValue(watchedString)
        }
        
        // Use safe value extraction for all optional fields
        let year = safeIntValue(from: columns, at: mapping["year"])
        let rating = safeDoubleValue(from: columns, at: mapping["rating"])
        let tmdbRating = safeDoubleValue(from: columns, at: mapping["tmdbrating"])
        let runtime = safeIntValue(from: columns, at: mapping["runtime"])
        let overview = safeStringValue(from: columns, at: mapping["overview"])
        let releaseDate = safeStringValue(from: columns, at: mapping["releasedate"])
        let tmdbId = safeStringValue(from: columns, at: mapping["tmdbid"])
        let directors = safeStringValue(from: columns, at: mapping["directors"])
        let cast = safeStringValue(from: columns, at: mapping["cast"])
        
        // Handle genres with backward compatibility
        let genres: String? = {
            if let genresValue = safeStringValue(from: columns, at: mapping["genres"]) {
                return genresValue
            }
            // Fall back to legacy "genre" field
            return safeStringValue(from: columns, at: mapping["genre"])
        }()
        
        // Handle posterPath with backward compatibility
        let posterPath: String? = {
            if let posterPathValue = safeStringValue(from: columns, at: mapping["posterpath"]) {
                return posterPathValue
            }
            // Fall back to legacy "poster" field
            return safeStringValue(from: columns, at: mapping["poster"])
        }()
        
        let backdropPath = safeStringValue(from: columns, at: mapping["backdroppath"])
        
        return Movie(
            title: title,
            watched: watched,
            year: year,
            rating: rating,
            tmdbRating: tmdbRating,
            posterPath: posterPath,
            backdropPath: backdropPath,
            runtime: runtime,
            genres: genres,
            overview: overview,
            releaseDate: releaseDate,
            tmdbId: tmdbId,
            directors: directors,
            cast: cast
        )
    }
}

enum CSVImportError: LocalizedError {
    case emptyFile
    case insufficientData
    case missingRequiredColumn(String)
    case unknownColumn(String)
    case inconsistentColumns(line: Int)
    case invalidData(line: Int, error: String)
    case emptyRequiredField(String)
    case invalidBooleanValue(String)
    
    var errorDescription: String? {
        switch self {
        case .emptyFile:
            return "The CSV file is empty."
        case .insufficientData:
            return "The CSV file must contain at least a header row and one data row."
        case .missingRequiredColumn(let column):
            return "Missing required column: '\(column)'"
        case .unknownColumn(let column):
            return "Unknown column: '\(column)'. See the supported columns list above."
        case .inconsistentColumns(let line):
            return "Line \(line) has a different number of columns than the header."
        case .invalidData(let line, let error):
            return "Invalid data on line \(line): \(error)"
        case .emptyRequiredField(let field):
            return "Required field '\(field)' cannot be empty."
        case .invalidBooleanValue(let value):
            return "Invalid boolean value: '\(value)'. Use 'true', 'false', 'yes', 'no', '1', or '0'. Empty values default to 'false'."
        }
    }
}

#Preview {
    CSVImportView()
        .modelContainer(for: Movie.self, inMemory: true)
} 
