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
        centerSegmentedToolbarItem()
        updateVC()
    }

    private func centerSegmentedToolbarItem() {
        // macOS's flexible-space items do not reliably center a toolbar item
        // when the titlebar has traffic lights consuming leading space.
        // Explicitly mark the segmented control as the centered item.
        guard #available(macOS 11.0, *),
              let toolbar = window?.toolbar,
              let item = toolbar.items.first(where: { $0.view is NSSegmentedControl })
        else { return }
        toolbar.centeredItemIdentifier = item.itemIdentifier
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
