import SwiftUI
import AppKit

struct MarkdownTextView: NSViewRepresentable {
    var markdown: String

    func makeNSView(context: Context) -> NSScrollView {
        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.backgroundColor = .clear
        textView.font = NSFont.systemFont(ofSize: 13)
        textView.textColor = NSColor.labelColor
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.linkTextAttributes = [.foregroundColor: NSColor.systemBlue]

        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.documentView = textView
        scroll.drawsBackground = false
        return scroll
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        DispatchQueue.main.async {
            let attributed: AttributedString
            do {
                attributed = try AttributedString(markdown: markdown, options: .init(interpretedSyntax: .full))
            } catch {
                attributed = AttributedString(markdown)
            }

            let ns = NSAttributedString(attributed)
            textView.textStorage?.setAttributedString(ns)
        }
    }
}
