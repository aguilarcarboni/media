//
//  BooksView.swift
//  media
//
//  Created by Andrés on 01/07/2025.
//

import SwiftUI
import SwiftData

struct BooksView: View {
    @Query private var books: [Book]
    @State private var selectedBook: Book?
    @State private var searchQuery = ""
    
    enum FilterOption: String, CaseIterable, Identifiable {
        case all = "All"
        case read = "Read"
        case unread = "Unread"
        var id: Self { self }
    }
    
    @State private var filterOption: FilterOption = .all
    
    private var filteredBooks: [Book] {
        books
            .filter { book in
                switch filterOption {
                case .all: return true
                case .read: return book.read
                case .unread: return !book.read
                }
            }
            .filter { bk in
                searchQuery.isEmpty ||
                bk.title.localizedCaseInsensitiveContains(searchQuery) ||
                bk.author.localizedCaseInsensitiveContains(searchQuery)
            }
    }
    
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
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredBooks) { book in
                        BookRowView(book: book)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedBook = book }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Books")
        .sheet(item: $selectedBook) { book in
            NavigationStack { BookView(book: book).navigationTitle(book.title) }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Picker("Filter", selection: $filterOption) {
                        ForEach(FilterOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .searchable(text: $searchQuery)
    }
}

struct BookRowView: View {
    @Bindable var book: Book
    var body: some View {
        HStack {
            AsyncImage(url: book.coverURL) { img in
                img.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle().fill(.secondary.opacity(0.2)).overlay { Image(systemName: "photo") }
            }
            .frame(width: 40, height: 60).clipShape(RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                Text(book.author)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let year = book.year { Text(String(year)).font(.caption).foregroundStyle(.secondary) }
            }
            Spacer()
            Button(action: {
                if book.read {
                    book.markAsUnread()
                } else {
                    book.markAsRead()
                }
            }) {
                Image(systemName: book.read ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(book.read ? .green : .secondary)
            }
            .buttonStyle(.borderless)
        }
    }
} 
