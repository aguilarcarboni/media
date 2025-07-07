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
    // New property to indicate whether the view is shown as a preview before saving
    var isPreview: Bool = false
    // Environment
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // Toolbar state
    @State private var showingDeleteAlert: Bool = false
    @State private var tempRating: Double

    // Custom initializer to support the `@Bindable` requirement
    init(book: Book, isPreview: Bool = false) {
        self._book = Bindable(wrappedValue: book)
        self.isPreview = isPreview
        _tempRating = State(initialValue: book.rating ?? book.appleRating ?? 0.5)
    }
    
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
            if isPreview {
                // Preview mode: Cancel / Add buttons
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        modelContext.insert(book)
                        dismiss()
                    }
                }
            } else {
                // Existing toolbar when the book is already saved
                // Delete button
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .tint(.red)
                }
                // Read toggle
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
                // Rating menu (only when read)
                if book.read {
                    ToolbarItem {
                        Menu {
                            Stepper(value: $tempRating, in: 0...10, step: 0.1) {
                                Text(String(format: "%.0f%%", tempRating * 10))
                            }
                            Button("Save") {
                                book.rating = tempRating
                                book.updated = Date()
                            }
                        } label: {
                            Image(systemName: book.rating != nil ? "star.circle.fill" : "star.circle")
                        }
                    }
                }
                // Overflow menu
                ToolbarItem() {
                    Menu {
                        if book.appleBookId != nil {
                            Button("Refresh from Store") { refreshFromAppleBooks() }
                        }
                    } label: { Image(systemName: "ellipsis") }
                }
            }
        }
        // Delete confirmation alert
        .alert("Delete Book?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                modelContext.delete(book)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
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
