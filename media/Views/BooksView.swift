//
//  BooksView.swift
//  media
//
//  Created by Andrés on 01/07/2025.
//

import SwiftUI
import SwiftData

struct BooksView: View {
    let books: [Book]
    @Binding var selectedBook: Book?
    @Binding var showingBookDetail: Bool
    @Binding var showingCreateSheet: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            if books.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    VStack(spacing: 8) {
                        Text("No Books Yet").font(.title2).bold()
                        Text("Add your first book to get started")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    Button(action: { showingCreateSheet = true }) {
                        Label("Add Book", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(books) { book in
                        Button(action: {
                            selectedBook = book
                            showingBookDetail = true
                        }) {
                            BookRowView(book: book)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Books (\(books.count))")
        .sheet(isPresented: $showingCreateSheet) { CreateBookView() }
        .sheet(isPresented: $showingBookDetail) {
            if let selectedBook = selectedBook {
                NavigationStack { BookView(book: selectedBook).navigationTitle(selectedBook.title) }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingCreateSheet = true }) {
                    Label("Add Item", systemImage: "plus")
                }
                .help("Add new book")
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }
}

struct BookRowView: View {
    let book: Book
    var body: some View {
        HStack {
            AsyncImage(url: book.coverURL) { img in
                img.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle().fill(.secondary.opacity(0.2)).overlay { Image(systemName: "photo") }
            }
            .frame(width: 40, height: 60).clipShape(RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title).font(.headline).strikethrough(book.read)
                Text(book.author).font(.caption).foregroundStyle(.secondary)
                HStack {
                    if let year = book.year { Text("\(year)").font(.caption).foregroundStyle(.secondary) }
                    if let rating = book.displayRating { Text("• ⭐ \(rating, specifier: "%.1f")").font(.caption).foregroundStyle(.secondary) }
                }
            }
            Spacer()
            if book.read {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            }
        }
    }
} 