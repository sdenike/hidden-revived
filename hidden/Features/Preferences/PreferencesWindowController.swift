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
        guard #available(macOS 11.0, *),
              let window = window,
              let toolbar = window.toolbar
        else { return }

        // .preference style is designed for tab-picker preferences windows:
        // it tightens the titlebar, integrates the toolbar, and centers the
        // primary toolbar item in the full window width.
        window.toolbarStyle = .preference

        guard let segmentedItem = toolbar.items.first(where: { $0.view is NSSegmentedControl })
        else { return }

        if #available(macOS 13.0, *) {
            toolbar.centeredItemIdentifiers = [segmentedItem.itemIdentifier]
        } else {
            toolbar.centeredItemIdentifier = segmentedItem.itemIdentifier
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
