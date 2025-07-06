//
//  BookView.swift
//  media
//
//  Created by Andrés on 01/07/2025.
//

import SwiftUI
import SwiftData

struct BookView: View {
    @Bindable var book: Book
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Cover and quick details card
                HStack(alignment: .top, spacing: 16) {
                    // Cover
                    AsyncImage(url: book.coverURL) { img in
                        img
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.secondary.opacity(0.3))
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.secondary)
                            }
                    }
                    .frame(width: 120, height: 180)

                    // Details
                    VStack(alignment: .leading, spacing: 12) {
                        // Read status
                        HStack {
                            Image(systemName: book.read ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(book.read ? .green : .secondary)
                                .font(.title2)
                            Text(book.read ? "Read" : "Not Read")
                                .font(.headline)
                                .foregroundStyle(book.read ? .green : .secondary)
                        }

                        // Quick details
                        VStack(alignment: .leading, spacing: 6) {
                            Label(book.author, systemImage: "person")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            if let year = book.year {
                                Label(String(year), systemImage: "calendar")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                            if !book.genreList.isEmpty {
                                Label(book.genreList.joined(separator: ", "), systemImage: "tag")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            if let releaseDate = book.releaseDate {
                                Label {
                                    Text(releaseDate, format: .dateTime.day().month().year())
                                } icon: {
                                    Image(systemName: "calendar")
                                }
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }

                            if let rating = book.displayRating {
                                Text("⭐ \(rating, specifier: "%.1f")")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()
                    }

                    Spacer()
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Synopsis
                if let synopsis = book.synopsis, !synopsis.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Synopsis").font(.headline)
                        Text(synopsis)
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Additional details
                VStack(alignment: .leading, spacing: 8) {
                    Text("Details").font(.headline)
                    VStack(spacing: 8) {
                        HStack { Text("Added:"); Spacer(); Text(book.created, format: .dateTime.day().month().year()) }
                        if book.updated != book.created {
                            HStack { Text("Updated:"); Spacer(); Text(book.updated, format: .dateTime.day().month().year()) }
                        }
                        if let appleId = book.appleBookId {
                            HStack { Text("Apple Book ID:"); Spacer(); Text(appleId).foregroundStyle(.secondary) }
                        }
                        if let userRating = book.rating {
                            HStack { Text("Your Rating:"); Spacer(); Text("⭐ \(userRating, specifier: "%.1f")") }
                        }
                        if let storeRating = book.appleRating {
                            HStack { Text("Store Rating:"); Spacer(); Text("⭐ \(storeRating, specifier: "%.1f")") }
                        }
                    }
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Spacer()
            }
            .padding()
        }
        .toolbar {
            ToolbarItem() {
                Button {
                    if book.read {
                        book.markAsUnread()
                    } else {
                        book.markAsRead()
                    }
                } label: {
                    Image(systemName: book.read ? "checkmark.circle.fill" : "circle")
                }
            }
            ToolbarItem() {
                Menu {
                    if book.appleBookId != nil {
                        Button("Refresh from Store") {
                            refreshFromAppleBooks()
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
    }
    private func refreshFromAppleBooks() {
        guard let idString = book.appleBookId, let id = Int(idString) else { return }
        Task {
            do {
                let details = try await AppleBooksAPIManager.shared.getBook(id: id)
                await MainActor.run {
                    book.updateFromAppleBooks(details)
                }
            } catch {
                print("Failed to refresh from Apple Books: \(error)")
            }
        }
    }
}
