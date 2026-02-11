//
//  PDFImport.swift
//  LectureToNotes
//
//  Created by Jacob Rodriguez on 5/9/25.
//

import Foundation
import PDFKit

class PDFImport {
    static func generateNotes(from fileURL: URL, completion: @escaping (String?) -> Void) {
        let fileExtension = fileURL.pathExtension.lowercased()
        var fullText = ""

        switch fileExtension {
        case "pdf":
            guard let pdf = PDFDocument(url: fileURL) else {
                print("❌ Failed to open PDF.")
                completion(nil)
                return
            }

            for pageIndex in 0..<pdf.pageCount {
                if let page = pdf.page(at: pageIndex),
                   let pageText = page.string {
                    fullText += pageText + "\n"
                }
            }

        case "txt":
            do {
                fullText = try String(contentsOf: fileURL, encoding: .utf8)
            } catch {
                print("❌ Failed to read TXT file: \(error.localizedDescription)")
                completion(nil)
                return
            }

        default:
            print("❌ Unsupported file type: \(fileExtension)")
            completion(nil)
            return
        }

        guard !fullText.isEmpty else {
            print("❌ Extracted text is empty.")
            completion(nil)
            return
        }

        OpenAIClient.shared.generateStudyNotes(from: fullText) { notes, tokens, cost in
            DispatchQueue.main.async {
                print("✅ Notes generated.")
                AudioRecorder.shared.formattedNotes = notes
                completion(notes)
            }
        }
    }
}
