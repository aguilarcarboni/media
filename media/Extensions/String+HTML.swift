//
//  String+HTML.swift
//  media
//
//  Created by Andrés on 01/07/2025.
//

import Foundation
import SwiftUI

extension String {
    /// Returns an AttributedString rendered from the HTML string. Returns nil if conversion fails.
    var htmlAttributed: AttributedString? {
        guard let data = self.data(using: .utf8) else { return nil }
        if let nsAttr = try? NSAttributedString(data: data,
                                                options: [.documentType: NSAttributedString.DocumentType.html,
                                                          .characterEncoding: String.Encoding.utf8.rawValue],
                                                documentAttributes: nil) {
            return AttributedString(nsAttr)
        }
        return nil
    }
    
    /// Returns plain text stripped of HTML tags & entities.
    var htmlStripped: String {
        return htmlAttributed?.description ?? self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
    }
} 