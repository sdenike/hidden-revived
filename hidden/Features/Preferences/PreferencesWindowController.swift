//
//  PreferencesWindowController.swift
//  Hidden Bar
//
//  Created by Phuc Le Dien on 2/22/19.
//  Copyright © 2019 Dwarves Foundation. All rights reserved.
//

import Cocoa

class PreferencesWindowController: NSWindowController {
    
    enum MenuSegment: Int {
        case general
        case about
    }
    
    static let shared: PreferencesWindowController = {
        let wc = NSStoryboard(name:"Main", bundle: nil).instantiateController(withIdentifier: "MainWindow") as! PreferencesWindowController
        return wc
    }()
    
    private var menuSegment: MenuSegment = .general {
        didSet {
            updateVC()
        }
    }
    
    private let preferencesVC = PreferencesViewController.initWithStoryboard()
    
    private let aboutVC = AboutViewController.initWithStoryboard()
    
    override func windowDidLoad() {
        super.windowDidLoad()
        configurePreferencesToolbar()
        updateVC()
    }

    private func configurePreferencesToolbar() {
        guard let window = window, let toolbar = window.toolbar else { return }

        // Tight single-row titlebar. Centering the pill across the full
        // window on macOS 26 Tahoe is unreliable under any toolbar style
        // (the system centers only within the post-traffic-lights region),
        // so the storyboard right-aligns it via a single leading flex
        // space instead — matching many modern macOS utility windows.
        window.toolbarStyle = .unifiedCompact

        // Let the content view extend behind the titlebar and make the
        // titlebar transparent so the content's `NSVisualEffectView`
        // shows through uninterrupted. This is how the titlebar and
        // content reach exactly the same material; otherwise Tahoe's
        // Liquid Glass titlebar renders subtly darker than any public
        // material enum we can set on an `NSVisualEffectView`.
        window.styleMask.insert(.fullSizeContentView)
        window.titlebarAppearsTransparent = true
        window.titlebarSeparatorStyle = .none

        guard let segmentedItem = toolbar.items.first(where: { $0.view is NSSegmentedControl })
        else { return }

        // Regular size gives the automatic-style pill enough internal
        // padding and text weight to read clearly once titlebar and
        // content share the same material.
        if let segmented = segmentedItem.view as? NSSegmentedControl {
            segmented.controlSize = .regular
        }
    }
    
    override func keyDown(with event: NSEvent) {
        super.keyDown(with: event)
        if let vc = self.contentViewController as? PreferencesViewController, vc.listening {
            vc.updateGlobalShortcut(event)
        }
    }
    
    override func flagsChanged(with event: NSEvent) {
        super.flagsChanged(with: event)
        if let vc = self.contentViewController as? PreferencesViewController, vc.listening {
            vc.updateModiferFlags(event)
        }
    }
    
    @IBAction func switchSegment(_ sender: NSSegmentedControl) {
        guard let segment = MenuSegment(rawValue: sender.indexOfSelectedItem) else {return}
        menuSegment = segment
    }
    
    private func updateVC() {
        switch menuSegment {
        case .general:
            self.window?.contentViewController = preferencesVC
        case .about:
            self.window?.contentViewController = aboutVC
        }
    }
    
}
