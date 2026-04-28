//
//  AboutViewController.swift
//  Hidden Bar Revived
//
//  Originally by phucld on 12/19/19 for Hidden Bar.
//  Updated to modernize the About screen for Hidden Bar Revived.
//

import Cocoa

class AboutViewController: NSViewController {

    @IBOutlet weak var lblVersion: NSTextField!

    static func initWithStoryboard() -> AboutViewController {
        let vc = NSStoryboard(name: "Main", bundle: nil)
            .instantiateController(withIdentifier: "aboutVC") as! AboutViewController
        return vc
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.installGlassBackground()
        view.clearOpaqueBoxFills()
        setupVersionLabel()
        refreshLinks()
    }

    private func setupVersionLabel() {
        guard let version = Bundle.main.releaseVersionNumber,
              let buildNumber = Bundle.main.buildVersionNumber else { return }
        lblVersion.stringValue = "Version \(version) (\(buildNumber))"
        lblVersion.font = .monospacedDigitSystemFont(ofSize: 13, weight: .regular)
    }

    // Replaces the legacy upstream "Know more about us / Twitter / open
    // source / Email us" rows with fork-first destinations. Rows are
    // matched by the storyboard's existing `href` prefix so reordering in
    // Interface Builder won't break the mapping.
    private func refreshLinks() {
        struct LinkSpec {
            let matchPrefix: String
            let title: String
            let href: String
            let symbolName: String
        }

        let specs: [LinkSpec] = [
            LinkSpec(matchPrefix: "https://dwarves.foundation",
                     title: "View on GitHub",
                     href: "https://github.com/sdenike/hidden-revived",
                     symbolName: "chevron.left.forwardslash.chevron.right"),
            LinkSpec(matchPrefix: "https://twitter.com",
                     title: "Download latest release",
                     href: "https://github.com/sdenike/hidden-revived/releases/latest",
                     symbolName: "arrow.down.circle.fill"),
            LinkSpec(matchPrefix: "https://github.com/sdenike",
                     title: "Report an issue",
                     href: "https://github.com/sdenike/hidden-revived/issues/new",
                     symbolName: "exclamationmark.bubble.fill"),
            LinkSpec(matchPrefix: "mailto:",
                     title: "View MIT License",
                     href: "https://github.com/sdenike/hidden-revived/blob/main/LICENSE",
                     symbolName: "doc.text.fill"),
        ]

        let symbolConfig = NSImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        let hyperlinks = view.descendants(ofType: HyperlinkTextField.self)
        let imageViews = view.descendants(ofType: NSImageView.self)

        // Pair each hyperlink with the image view immediately preceding it
        // in the storyboard's link rows, then apply the new title, href,
        // and SF Symbol icon together.
        for hyperlink in hyperlinks {
            guard let spec = specs.first(where: { hyperlink.href.hasPrefix($0.matchPrefix) }) else { continue }
            hyperlink.stringValue = spec.title
            hyperlink.href = spec.href
            hyperlink.toolTip = spec.href

            if let icon = imageViews.first(where: { $0.superview === hyperlink.superview && $0 !== hyperlink }),
               let symbol = NSImage(systemSymbolName: spec.symbolName, accessibilityDescription: spec.title) {
                icon.image = symbol.withSymbolConfiguration(symbolConfig)
                icon.contentTintColor = .labelColor
            }
        }
    }
}
