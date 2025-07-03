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
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: book.coverURL) { img in
                        img.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle().fill(.secondary.opacity(0.3)).overlay {
                            Image(systemName: "photo").font(.system(size: 48)).foregroundStyle(.secondary)
                        }
                    }
                    .frame(height: 250).clipped()
                    LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(book.title).font(.largeTitle).bold().foregroundStyle(.white)
                        Text(book.author).font(.title3).foregroundStyle(.white.opacity(0.9))
                        if let rating = book.displayRating {
                            Text("⭐ \(rating, specifier: "%.1f")").font(.title3).foregroundStyle(.white.opacity(0.9))
                        }
                    }
                    .padding()
                }
                .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: book.read ? "checkmark.circle.fill" : "circle").foregroundStyle(book.read ? .green : .secondary).font(.title2)
                        Text(book.read ? "Read" : "Not Read").font(.headline).foregroundStyle(book.read ? .green : .secondary)
                    }
                    if !book.genreList.isEmpty {
                        Label(book.genreList.joined(separator: ", "), systemImage: "tag").font(.subheadline).foregroundStyle(.secondary)
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
                }
                
                if let synopsis = book.synopsis, !synopsis.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Synopsis").font(.headline)
                        if let attr = synopsis.htmlAttributed {
                            Text(attr)
                        } else {
                            Text(synopsis.htmlStripped)
                        }
                    }
                    .padding().background(.regularMaterial).cornerRadius(8)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Details").font(.headline)
                    VStack(spacing: 8) {
                        HStack { Text("Added:"); Spacer(); Text(book.created, format: .dateTime.day().month().year()) }
                        if book.updated != book.created {
                            HStack { Text("Updated:"); Spacer(); Text(book.updated, format: .dateTime.day().month().year()) }
                        }
                        if let appleId = book.appleBookId { HStack { Text("Apple Book ID:"); Spacer(); Text(appleId).foregroundStyle(.secondary) } }
                        if book.rating != nil && book.appleRating != nil {
                            HStack { Text("Your Rating:"); Spacer(); Text("⭐ \(book.rating!, specifier: "%.1f")") }
                            HStack { Text("Store Rating:"); Spacer(); Text("⭐ \(book.appleRating!, specifier: "%.1f")") }
                        }
                    }
                }
                .padding().background(.regularMaterial).cornerRadius(8)
                Spacer()
            }
            .padding()
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(book.read ? "Mark Unread" : "Mark Read") {
                    if book.read { book.markAsUnread() } else { book.markAsRead() }
                }
            }
        }
    }
} 