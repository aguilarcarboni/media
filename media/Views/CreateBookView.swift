//
//  CreateBookView.swift
//  media
//
//  Created by Andrés on 01/07/2025.
//

import SwiftUI
import SwiftData

struct CreateBookView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingPreview = false
    // Book fields
    @State private var title = ""
    @State private var author = ""
    @State private var year = ""
    @State private var rating = ""
    @State private var genre = ""
    @State private var synopsis = ""
    
    // Apple Books integration
    @State private var searchQuery = ""
    @State private var searchResults: [AppleBookSearchResult] = []
    @State private var isSearching = false
    @State private var selectedBookDetails: AppleBookDetails?
    @State private var isLoadingDetails = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            if showingPreview { previewView } else { mainView }
        }
        .alert("Error", isPresented: $showingError) { Button("OK"){} } message: { Text(errorMessage) }
    }
    
    private var mainView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                HStack {
                    TextField("Search for a book...", text: $searchQuery).textFieldStyle(.roundedBorder).onSubmit { searchBooks() }
                    Button(action: searchBooks) {
                        if isSearching { ProgressView().scaleEffect(0.8) } else { Image(systemName: "magnifyingglass").foregroundColor(.accentColor) }
                    }.disabled(isSearching || searchQuery.trimmingCharacters(in: .whitespaces).isEmpty).buttonStyle(.bordered)
                }
                if isSearching { ProgressView("Searching Books...").padding() }
            }
            if !searchResults.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 12) { ForEach(searchResults.prefix(10)) { result in bookSearchRow(result) } }.padding(.horizontal)
                }
            } else if !searchQuery.isEmpty && !isSearching {
                VStack(spacing: 8){ Image(systemName:"magnifyingglass").font(.system(size:32)).foregroundStyle(.secondary); Text("No results found").font(.headline).foregroundStyle(.secondary); Text("Try a different search term").font(.caption).foregroundStyle(.secondary) }.frame(maxWidth:.infinity,maxHeight:.infinity)
            }
            Spacer()
        }.padding().navigationTitle("Add Book").toolbar { ToolbarItem(placement:.cancellationAction){ Button("Cancel"){ dismiss() } } }
    }
    
    private func bookSearchRow(_ result: AppleBookSearchResult) -> some View {
        Button{ selectBook(result) } label: {
            HStack(spacing:12){
                AsyncImage(url: result.coverURL){ img in img.resizable().aspectRatio(contentMode:.fill)} placeholder: { Rectangle().fill(.secondary.opacity(0.2)).overlay{Image(systemName:"photo").foregroundStyle(.secondary)} }.frame(width:40,height:60).clipShape(RoundedRectangle(cornerRadius:6))
                VStack(alignment:.leading,spacing:4){ Text(result.trackName ?? "Unknown").font(.headline).foregroundStyle(.primary)
                    Text(result.artistName ?? "").font(.subheadline).foregroundStyle(.secondary)
                    if let year = result.year { Text("\(year)").font(.caption).foregroundStyle(.secondary) }
                }
                Spacer()
                if isLoadingDetails { ProgressView().scaleEffect(0.8) } else { Image(systemName:"chevron.right").foregroundStyle(.secondary) }
            }.padding().cornerRadius(12).shadow(color:.black.opacity(0.1),radius:2,x:0,y:1)
        }.buttonStyle(.plain)
    }
    
    private var previewView: some View {
        ScrollView {
            VStack(spacing:24){ Text("Preview").font(.largeTitle).bold()
                VStack(spacing:16){ previewRow("Title", value:title); previewRow("Author", value:author); previewRow("Year", value:year.isEmpty ? "Unknown":year); previewRow("Genre", value:genre.isEmpty ? "Unknown":genre); previewRow("Rating", value:rating.isEmpty ? "Unrated":rating); if !synopsis.isEmpty { previewRow("Synopsis", value:synopsis,isLong:true) }
                    if selectedBookDetails != nil { HStack{ Image(systemName:"checkmark.circle.fill").foregroundColor(.green); Text("Imported from Apple Books").font(.caption).foregroundStyle(.secondary); Spacer() } }
                }.padding().cornerRadius(16)
                VStack(spacing:12){ Button(action:addBook){ Text("Add Book").font(.headline).foregroundColor(.white).frame(maxWidth:.infinity).padding().background(Color.accentColor).cornerRadius(12) }
                    Button("Back to Edit"){ showingPreview = false }.font(.headline).foregroundColor(.accentColor).frame(maxWidth:.infinity).padding().cornerRadius(12)
                }
            }.padding()
        }.navigationTitle("Add Book").toolbar { ToolbarItem(placement:.cancellationAction){ Button("Cancel"){ dismiss() } } }
    }
    
    private func previewRow(_ label: String, value: String, isLong: Bool = false) -> some View {
        VStack(alignment:.leading,spacing:4){ Text(label).font(.caption).foregroundStyle(.secondary).textCase(.uppercase); Text(value).font(isLong ? .body:.headline).foregroundStyle(.primary) }.frame(maxWidth:.infinity,alignment:.leading)
    }
    
    // MARK: Actions
    private func searchBooks(){ guard !searchQuery.trimmingCharacters(in:.whitespaces).isEmpty else { return } ; isSearching = true; searchResults=[]; Task{ do{ let res = try await AppleBooksAPIManager.shared.searchBooks(term:searchQuery); await MainActor.run { searchResults = res; isSearching=false } } catch { await MainActor.run{ isSearching=false; errorMessage=error.localizedDescription; showingError=true } } }
    }
    private func selectBook(_ result: AppleBookSearchResult){ isLoadingDetails=true; Task{ do{ let details = try await AppleBooksAPIManager.shared.getBook(id: result.trackId); await MainActor.run { populateFields(details); selectedBookDetails = details; isLoadingDetails=false; searchResults=[]; searchQuery=""; showingPreview=true } } catch { await MainActor.run{ isLoadingDetails=false; errorMessage=error.localizedDescription; showingError=true } } }
    }
    private func populateFields(_ details: AppleBookDetails) {
        title = details.trackName ?? ""
        author = details.artistName ?? ""
        if let y = details.year { year = String(y) }
        synopsis = details.description ?? ""
        genre = details.genreNames
    }
    private func addBook(){ let newBook: Book; if let det = selectedBookDetails { newBook = Book(); newBook.updateFromAppleBooks(det); } else { newBook = Book() }
        applyManualEdits(to:newBook); modelContext.insert(newBook); dismiss() }
    private func applyManualEdits(to book: Book){ book.title = title.trimmingCharacters(in:.whitespacesAndNewlines); book.author = author.trimmingCharacters(in:.whitespacesAndNewlines); if let y = Int(year) { book.year=y }; if let r = Double(rating) { book.rating = r }; let genreText = genre.trimmingCharacters(in:.whitespacesAndNewlines); book.genres = genreText.isEmpty ? nil : genreText; let synopsisText = synopsis.trimmingCharacters(in:.whitespacesAndNewlines); book.synopsis = synopsisText.isEmpty ? nil : synopsisText }
} 
