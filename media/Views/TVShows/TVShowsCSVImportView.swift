//
//  TVShowsCSVImportView.swift
//  media
//
//  Created by Andrés on 28/6/2025.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct TVShowsCSVImportView: View {
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
                        Image(systemName: "tv")
                            .font(.system(size: 50))
                            .foregroundStyle(.blue)
                        
                        VStack(spacing: 8) {
                            Text("Import TV Shows CSV")
                                .font(.title2)
                                .bold()
                            
                            Text("Select a CSV file to import TV shows")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    // CSV structure info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("CSV Structure (based on your file):")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 4))
                                    .foregroundStyle(.secondary)
                                Text("rating (string) - Optional (e.g., \"95%\")")
                            }
                            HStack {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 4))
                                    .foregroundStyle(.secondary)
                                Text("name (string) - Required")
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
                                Text("genre (string) - Optional")
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
                                Text("seasons (string) - Optional (semicolon-separated)")
                            }
                            HStack {
                                Image(systemName: "circle")
                                    .font(.system(size: 4))
                                    .foregroundStyle(.secondary)
                                Text("airDate (string) - Optional (MM/DD/YYYY)")
                            }
                            HStack {
                                Image(systemName: "circle")
                                    .font(.system(size: 4))
                                    .foregroundStyle(.secondary)
                                Text("tmdbId (string) - Optional")
                            }
                        }
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        
                        Text("Note: Additional optional fields: posterPath, backdropPath, creators, cast, status, numberOfSeasons, numberOfEpisodes")
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
                                    Text("Successfully imported \(count) TV shows!")
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
            .navigationTitle("Import TV Shows CSV")
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
                let tvShows = try parseCSV(csvData)
                
                await MainActor.run {
                    // Add TV shows to model context
                    for tvShow in tvShows {
                        modelContext.insert(tvShow)
                    }
                    
                    try? modelContext.save()
                    importResult = .success(count: tvShows.count)
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
    
    private func parseCSV(_ csvContent: String) throws -> [TVShow] {
        let lines = csvContent.components(separatedBy: .newlines)
        guard !lines.isEmpty else {
            throw TVShowCSVImportError.emptyFile
        }
        
        // Remove empty lines
        let nonEmptyLines = lines.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard nonEmptyLines.count >= 2 else {
            throw TVShowCSVImportError.insufficientData
        }
        
        // Parse header
        let header = parseCSVLine(nonEmptyLines[0])
        try validateHeader(header)
        
        // Create column mapping
        let columnMapping = createColumnMapping(header)
        
        var tvShows: [TVShow] = []
        
        for lineIndex in 1..<nonEmptyLines.count {
            let line = nonEmptyLines[lineIndex]
            let columns = parseCSVLine(line)
            
            guard columns.count == header.count else {
                throw TVShowCSVImportError.inconsistentColumns(line: lineIndex + 1)
            }
            
            do {
                let tvShow = try createTVShow(from: columns, using: columnMapping)
                tvShows.append(tvShow)
            } catch {
                throw TVShowCSVImportError.invalidData(line: lineIndex + 1, error: error.localizedDescription)
            }
        }
        
        return tvShows
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
        let requiredColumns = ["name"]
        let optionalColumns = [
            "rating", "year", "genre", "overview", "seasons", "airDate", "tmdbId",
            "posterPath", "backdropPath", "creators", "cast", "status", 
            "numberOfSeasons", "numberOfEpisodes", "tmdbRating"
        ]
        let allowedColumns = requiredColumns + optionalColumns
        
        // Check for required columns
        for required in requiredColumns {
            if !header.contains(where: { $0.lowercased() == required.lowercased() }) {
                throw TVShowCSVImportError.missingRequiredColumn(required)
            }
        }
        
        // Check for unknown columns
        for column in header {
            if !allowedColumns.contains(where: { $0.lowercased() == column.lowercased() }) {
                throw TVShowCSVImportError.unknownColumn(column)
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
        
        // Handle percentage ratings like "95%"
        if stringValue.hasSuffix("%") {
            let numericPart = String(stringValue.dropLast())
            if let percentage = Double(numericPart) {
                return percentage / 10.0 // Convert 95% to 9.5
            }
        }
        
        return Double(stringValue)
    }
    
    private func createTVShow(from columns: [String], using mapping: [String: Int]) throws -> TVShow {
        guard let nameIndex = mapping["name"] else {
            throw TVShowCSVImportError.missingRequiredColumn("name")
        }
        
        let name = columns[nameIndex].trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            throw TVShowCSVImportError.emptyRequiredField("name")
        }
        
        // Use safe value extraction for all optional fields
        let year = safeIntValue(from: columns, at: mapping["year"])
        let rating = safeDoubleValue(from: columns, at: mapping["rating"])
        let tmdbRating = safeDoubleValue(from: columns, at: mapping["tmdbrating"])
        let overview = safeStringValue(from: columns, at: mapping["overview"])
        let tmdbId = safeStringValue(from: columns, at: mapping["tmdbid"])
        let creators = safeStringValue(from: columns, at: mapping["creators"])
        let cast = safeStringValue(from: columns, at: mapping["cast"])
        let status = safeStringValue(from: columns, at: mapping["status"])
        let numberOfSeasons = safeIntValue(from: columns, at: mapping["numberofseasons"])
        let numberOfEpisodes = safeIntValue(from: columns, at: mapping["numberofepisodes"])
        let posterPath = safeStringValue(from: columns, at: mapping["posterpath"])
        let backdropPath = safeStringValue(from: columns, at: mapping["backdroppath"])
        
        // Handle genre
        let genres = safeStringValue(from: columns, at: mapping["genre"])
        
        // Handle seasons
        let seasons = safeStringValue(from: columns, at: mapping["seasons"])
        
        // Handle air date - convert MM/DD/YYYY to yyyy-MM-dd if needed
        let airDate: String? = {
            guard let airDateString = safeStringValue(from: columns, at: mapping["airdate"]) else { return nil }
            
            // Try to parse MM/DD/YYYY format
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/yyyy"
            if let date = dateFormatter.date(from: airDateString) {
                let outputFormatter = DateFormatter()
                outputFormatter.dateFormat = "yyyy-MM-dd"
                return outputFormatter.string(from: date)
            }
            
            // If parsing fails, use original string
            return airDateString
        }()
        
        return TVShow(
            name: name,
            watched: false, // Default to not watched
            year: year,
            rating: rating,
            tmdbRating: tmdbRating,
            posterPath: posterPath,
            backdropPath: backdropPath,
            seasons: seasons,
            genres: genres,
            overview: overview,
            airDate: airDate,
            tmdbId: tmdbId,
            creators: creators,
            cast: cast,
            status: status,
            numberOfSeasons: numberOfSeasons,
            numberOfEpisodes: numberOfEpisodes
        )
    }
}

enum TVShowCSVImportError: LocalizedError {
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
    TVShowsCSVImportView()
        .modelContainer(for: TVShow.self, inMemory: true)
} 