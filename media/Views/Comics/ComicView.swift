//
//  ComicView.swift
//  media
//
//  Created by Andrés on 6/7/2025.
//

import SwiftUI
import SwiftData

struct ComicView: View {
    @Bindable var comic: Comic
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Cover image
                AsyncImage(url: comic.coverURL) { img in
                    img.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    Rectangle().fill(.secondary.opacity(0.3)).overlay {
                        Image(systemName: "photo").font(.system(size: 48)).foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Text(comic.title).font(.largeTitle).bold()
                if let issue = comic.issueNumber {
                    Text("Issue #\(issue)").font(.title3).foregroundStyle(.secondary)
                }
                if let series = comic.seriesName {
                    Text(series).font(.headline)
                }
                if let synopsis = comic.synopsis, !synopsis.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Synopsis").font(.headline)
                        Text(synopsis).font(.body)
                    }
                }
                if !creatorText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Creators").font(.headline)
                        Text(creatorText).font(.body)
                    }
                }
                if !characterText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Characters").font(.headline)
                        Text(characterText).font(.body)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle(comic.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(comic.read ? "Mark Unread" : "Mark Read") {
                    if comic.read { comic.markAsUnread() } else { comic.markAsRead() }
                }
            }
        }
    }
    
    private var creatorText: String {
        [comic.writers, comic.artists].compactMap { $0 }.joined(separator: ", ")
    }
    private var characterText: String { comic.characters ?? "" }
} 