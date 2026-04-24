//
//  NSView+Glass.swift
//  Hidden Bar Revived
//
//  Helpers for installing an `NSVisualEffectView` backdrop behind a
//  storyboard-loaded root view so that the window's Liquid Glass material
//  extends through the content area instead of butting against a solid
//  window background.
//

import AppKit

extension NSView {

    /// Inserts a full-bleed `NSVisualEffectView` at the back of the view
    /// hierarchy. Must be called after the view has been loaded from its
    /// storyboard (e.g. inside `viewDidLoad`).
    func installGlassBackground() {
        let effect = NSVisualEffectView()
        effect.blendingMode = .behindWindow
        effect.state = .followsWindowActiveState
        if #available(macOS 10.14, *) {
            effect.material = .underWindowBackground
        } else {
            effect.material = .sidebar
        }
        effect.translatesAutoresizingMaskIntoConstraints = false

        addSubview(effect, positioned: .below, relativeTo: subviews.first)
        NSLayoutConstraint.activate([
            effect.topAnchor.constraint(equalTo: topAnchor),
            effect.leadingAnchor.constraint(equalTo: leadingAnchor),
            effect.trailingAnchor.constraint(equalTo: trailingAnchor),
            effect.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    /// Recursively clears opaque fills on nested `NSBox` subviews so the
    /// glass backdrop shows through instead of the banded "card" look the
    /// default `quaternaryLabelColor` fill produces on dark appearance.
    func clearOpaqueBoxFills() {
        for subview in subviews {
            (subview as? NSBox)?.fillColor = .clear
            subview.clearOpaqueBoxFills()
        }
    }

    /// Returns every descendant view that matches the given type. Used to
    /// locate storyboard-authored elements without adding outlets for them.
    func descendants<T: NSView>(ofType type: T.Type) -> [T] {
        var matches: [T] = []
        for subview in subviews {
            if let match = subview as? T {
                matches.append(match)
            }
            matches.append(contentsOf: subview.descendants(ofType: type))
        }
        return matches
    }
}
