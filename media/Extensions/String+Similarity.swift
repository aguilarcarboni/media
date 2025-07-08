import Foundation

extension String {
    /// Computes the Levenshtein (edit) distance between this string and another one.
    /// A lower number means the strings are more similar. Complexity is O(m×n) where m and n are the lengths of the strings.
    func levenshteinDistance(from other: String) -> Int {
        let s = Array(self.lowercased())
        let t = Array(other.lowercased())
        let n = s.count
        let m = t.count
        if n == 0 { return m }
        if m == 0 { return n }

        var distance = Array(repeating: Array(repeating: 0, count: m + 1), count: n + 1)
        for i in 0...n { distance[i][0] = i }
        for j in 0...m { distance[0][j] = j }

        for i in 1...n {
            for j in 1...m {
                if s[i - 1] == t[j - 1] {
                    distance[i][j] = distance[i - 1][j - 1] // no operation needed
                } else {
                    let deletion = distance[i - 1][j] + 1
                    let insertion = distance[i][j - 1] + 1
                    let substitution = distance[i - 1][j - 1] + 1
                    distance[i][j] = Swift.min(deletion, insertion, substitution)
                }
            }
        }
        return distance[n][m]
    }

    /// Rough relevance score of how well this string matches a query. Higher is more relevant.
    /// Performs quick checks (exact, prefix, contains) before falling back to edit distance.
    func relevanceScore(to query: String) -> Int {
        let target = self.lowercased()
        let q = query.lowercased()

        if target == q { return Int.max }                  // exact match – highest priority
        if target.hasPrefix(q) { return Int.max - 1 }      // begins with query
        if target.contains(q) { return Int.max - 2 }       // query occurs within

        // Fallback to negative Levenshtein distance so that smaller distance → larger score
        // (we negate because we sort descending later)
        return -levenshteinDistance(from: q)
    }
} 
