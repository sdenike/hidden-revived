//
//  ViewController.swift
//  vanillaClone
//
//  Created by Thanh Nguyen on 1/24/19.
//  Copyright © 2019 Dwarves Foundation. All rights reserved.
//

import Cocoa
import Carbon
import HotKey

class PreferencesViewController: NSViewController {
    
   
    //MARK: - Outlets
    @IBOutlet weak var checkBoxKeepLastState: NSButton!
    @IBOutlet weak var textFieldTitle: NSTextField!
    @IBOutlet weak var imageViewTop: NSImageView!
    
    @IBOutlet weak var statusBarStackView: NSStackView!
    @IBOutlet weak var arrowPointToHiddenImage: NSImageView!
    @IBOutlet weak var arrowPointToAlwayHiddenImage: NSImageView!
    @IBOutlet weak var lblAlwayHidden: NSTextField!
    
    
    
    @IBOutlet weak var checkBoxAutoHide: NSButton!
    @IBOutlet weak var checkBoxKeepInDock: NSButton!
    @IBOutlet weak var checkBoxLogin: NSButton!
    @IBOutlet weak var checkBoxShowPreferences: NSButton!
    @IBOutlet weak var checkBoxShowAlwaysHiddenSection: NSButton!
    
    @IBOutlet weak var checkBoxUseFullStatusbar: NSButton!
    @IBOutlet weak var timePopup: NSPopUpButton!
    
    @IBOutlet weak var btnClear: NSButton!
    @IBOutlet weak var btnShortcut: NSButton!
    
    public var listening = false {
        didSet {
            let isHighlight = listening

            DispatchQueue.main.async { [weak self] in
                self?.btnShortcut.highlight(isHighlight)
            }
        }
    }

    // Retained so we can deactivate the previous set before re-adding on
    // every tutorial rebuild — otherwise Auto Layout accumulates a new
    // center-X constraint each toggle, which eventually logs unsatisfiable
    // constraint warnings and can break the arrow layout.
    private var hiddenArrowConstraint: NSLayoutConstraint?
    private var alwayHiddenArrowConstraint: NSLayoutConstraint?
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    //MARK: - VC Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.installGlassBackground()
        view.clearOpaqueBoxFills()
        updateData()
        loadHotkey()
        createTutorialView()
        NotificationCenter.default.addObserver(self, selector: #selector(updateData), name: .prefsChanged, object: nil)
    }
    
    static func initWithStoryboard() -> PreferencesViewController {
        let vc = NSStoryboard(name:"Main", bundle: nil).instantiateController(withIdentifier: "prefVC") as! PreferencesViewController
        return vc
    }
    
    //MARK: - Actions
    @IBAction func loginCheckChanged(_ sender: NSButton) {
        Preferences.isAutoStart = sender.state == .on
    }
    
    @IBAction func autoHideCheckChanged(_ sender: NSButton) {
        Preferences.isAutoHide = sender.state == .on
    }
    
    @IBAction func showPreferencesChanged(_ sender: NSButton) {
        Preferences.isShowPreference = sender.state == .on
    }
    
    
    @IBAction func showAlwaysHiddenSectionChanged(_ sender: NSButton) {
        Preferences.alwaysHiddenSectionEnabled = sender.state == .on
        createTutorialView()
    }
    @IBAction func useFullStatusBarOnExpandChanged(_ sender: NSButton) {
        Preferences.useFullStatusBarOnExpandEnabled = sender.state == .on
    }
    
    
    @IBAction func timePopupDidSelected(_ sender: NSPopUpButton) {
        let selectedIndex = sender.indexOfSelectedItem
        if let selectedInSecond = SelectedSecond(rawValue: selectedIndex)?.toSeconds() {
            Preferences.numberOfSecondForAutoHide = selectedInSecond
        }
    }
    
    // When the set shortcut button is pressed start listening for the new shortcut
    @IBAction func register(_ sender: Any) {
        listening = true
        view.window?.makeFirstResponder(nil)
    }
    
    // If the shortcut is cleared, clear the UI and tell AppDelegate to stop listening to the previous keybind.
    @IBAction func unregister(_ sender: Any?) {
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        appDelegate.hotKey = nil
        btnShortcut.title = "Set Shortcut".localized
        listening = false
        btnClear.isEnabled = false
        
        // Remove globalkey from userdefault
        Preferences.globalKey = nil
    }
    
    public func updateGlobalShortcut(_ event: NSEvent) {
        self.listening = false
        
        guard let characters = event.charactersIgnoringModifiers else {return}
        
        let newGlobalKeybind = GlobalKeybindPreferences(
            function: event.modifierFlags.contains(.function),
            control: event.modifierFlags.contains(.control),
            command: event.modifierFlags.contains(.command),
            shift: event.modifierFlags.contains(.shift),
            option: event.modifierFlags.contains(.option),
            capsLock: event.modifierFlags.contains(.capsLock),
            carbonFlags: event.modifierFlags.carbonFlags,
            characters: characters,
            keyCode: uint32(event.keyCode))
        
        Preferences.globalKey = newGlobalKeybind
        
        updateKeybindButton(newGlobalKeybind)
        btnClear.isEnabled = true
        
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        appDelegate.hotKey = HotKey(keyCombo: KeyCombo(carbonKeyCode: UInt32(event.keyCode), carbonModifiers: event.modifierFlags.carbonFlags))
    }
    
    public func updateModiferFlags(_ event: NSEvent) {
        let newGlobalKeybind = GlobalKeybindPreferences(
            function: event.modifierFlags.contains(.function),
            control: event.modifierFlags.contains(.control),
            command: event.modifierFlags.contains(.command),
            shift: event.modifierFlags.contains(.shift),
            option: event.modifierFlags.contains(.option),
            capsLock: event.modifierFlags.contains(.capsLock),
            carbonFlags: 0,
            characters: nil,
            keyCode: uint32(event.keyCode))
        
        updateModifierbindButton(newGlobalKeybind)
        
    }
    
    @objc private func updateData(){
        checkBoxUseFullStatusbar.state = Preferences.useFullStatusBarOnExpandEnabled ? .on : .off
        checkBoxLogin.state = Preferences.isAutoStart ? .on : .off
        checkBoxAutoHide.state = Preferences.isAutoHide ? .on : .off
        checkBoxShowPreferences.state = Preferences.isShowPreference ? .on : .off
        checkBoxShowAlwaysHiddenSection.state = Preferences.alwaysHiddenSectionEnabled ? .on : .off
        timePopup.selectItem(at: SelectedSecond.secondToPossition(seconds: Preferences.numberOfSecondForAutoHide))
    }
    
    private func loadHotkey() {
        if let globalKey = Preferences.globalKey {
            updateKeybindButton(globalKey)
            updateClearButton(globalKey)
        }
    }
    
    // Set the shortcut button to show the keys to press
    private func updateKeybindButton(_ globalKeybindPreference : GlobalKeybindPreferences) {
        btnShortcut.title = globalKeybindPreference.description
        
        if globalKeybindPreference.description.count <= 1 {
            unregister(nil)
        }
    }
    
    // Set the shortcut button to show the modifier to press
      private func updateModifierbindButton(_ globalKeybindPreference : GlobalKeybindPreferences) {
          btnShortcut.title = globalKeybindPreference.description
          
          if globalKeybindPreference.description.isEmpty {
              unregister(nil)
          }
      }
    
    // If a keybind is set, allow users to clear it by enabling the clear button.
    private func updateClearButton(_ globalKeybindPreference : GlobalKeybindPreferences?) {
        btnClear.isEnabled = globalKeybindPreference != nil
    }
}

//MARK: - Show tutorial
extension PreferencesViewController {
    
    func createTutorialView() {
        if Preferences.alwaysHiddenSectionEnabled {
            alwayHideStatusBar()
        }else {
            hideStatusBar()
        }
    }
    
    func hideStatusBar() {
        lblAlwayHidden.isHidden = true
        arrowPointToAlwayHiddenImage.isHidden = true
        rebuildStatusBar(with: ["ico_1", "ico_2", "ico_3", "seprated", "ico_collapse", "ico_4", "ico_5", "ico_6", "ico_7"])

        deactivateArrowConstraints()
        hiddenArrowConstraint = arrowPointToHiddenImage.centerXAnchor.constraint(
            equalTo: statusBarStackView.arrangedSubviews[3].centerXAnchor
        )
        hiddenArrowConstraint?.isActive = true
    }

    func alwayHideStatusBar() {
        lblAlwayHidden.isHidden = false
        arrowPointToAlwayHiddenImage.isHidden = false
        rebuildStatusBar(with: ["ico_1", "ico_2", "ico_3", "ico_4", "seprated_1", "ico_5", "ico_6", "seprated", "ico_collapse", "ico_7"])

        deactivateArrowConstraints()
        alwayHiddenArrowConstraint = arrowPointToAlwayHiddenImage.centerXAnchor.constraint(
            equalTo: statusBarStackView.arrangedSubviews[4].centerXAnchor
        )
        alwayHiddenArrowConstraint?.isActive = true
        hiddenArrowConstraint = arrowPointToHiddenImage.centerXAnchor.constraint(
            equalTo: statusBarStackView.arrangedSubviews[7].centerXAnchor
        )
        hiddenArrowConstraint?.isActive = true
    }

    private func deactivateArrowConstraints() {
        hiddenArrowConstraint?.isActive = false
        alwayHiddenArrowConstraint?.isActive = false
        hiddenArrowConstraint = nil
        alwayHiddenArrowConstraint = nil
    }

    // Rebuilds the mock menu-bar preview in the tutorial. Uses a nil-safe
    // image lookup so a missing / renamed asset no longer crashes the app
    // on Preferences open; layout is preserved because each slot still
    // produces an `NSImageView`, just with a blank image in the rare case
    // the asset disappears.
    private func rebuildStatusBar(with imageNames: [String]) {
        statusBarStackView.removeAllSubViews()
        let imageWidth: CGFloat = 16

        for name in imageNames {
            let image = NSImage(named: name)
            assert(image != nil, "Missing tutorial asset: \(name)")
            let imageView = NSImageView(image: image ?? NSImage())
            imageView.translatesAutoresizingMaskIntoConstraints = false
            statusBarStackView.addArrangedSubview(imageView)
            NSLayoutConstraint.activate([
                imageView.widthAnchor.constraint(equalToConstant: imageWidth),
                imageView.heightAnchor.constraint(equalToConstant: imageWidth),
            ])
            if #available(macOS 10.14, *) {
                imageView.contentTintColor = .labelColor
            }
        }

        let dateTimeLabel = NSTextField()
        dateTimeLabel.stringValue = Date.dateString() + " " + Date.timeString()
        dateTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        dateTimeLabel.isBezeled = false
        dateTimeLabel.isEditable = false
        dateTimeLabel.sizeToFit()
        dateTimeLabel.backgroundColor = .clear
        statusBarStackView.addArrangedSubview(dateTimeLabel)
        NSLayoutConstraint.activate([
            dateTimeLabel.heightAnchor.constraint(equalToConstant: imageWidth),
        ])
    }
    
    @IBAction func btnAlwayHiddenHelpPressed(_ sender: NSButton) {
        self.showHowToUseAlwayHiddenPopover(sender: sender)
    }
    
    private func showHowToUseAlwayHiddenPopover(sender: NSButton) {
        let rawText = NSLocalizedString("Tutorial text", comment: "Step by step tutorial")
        let attributed = tutorialAttributedString(from: rawText)

        let label = NSTextField(labelWithAttributedString: attributed)
        label.isSelectable = false
        label.lineBreakMode = .byWordWrapping
        label.maximumNumberOfLines = 0
        label.preferredMaxLayoutWidth = 340
        label.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView()
        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 18),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -18),
            label.widthAnchor.constraint(equalToConstant: 340),
        ])

        let controller = NSViewController()
        controller.view = container
        container.layoutSubtreeIfNeeded()

        let popover = NSPopover()
        popover.contentViewController = controller
        popover.contentSize = container.fittingSize
        popover.behavior = .transient
        popover.animates = true

        popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .maxX)
    }

    // Formats the localized tutorial string so section headings (lines
    // ending in ":") read as semibold secondary-label subtitles and body
    // paragraphs get comfortable line height + paragraph spacing. Works
    // across localizations because the pattern (headers with a trailing
    // colon, numbered items beginning with digit + ".") is preserved in
    // every translation this project ships.
    private func tutorialAttributedString(from text: String) -> NSAttributedString {
        let bodyFont = NSFont.systemFont(ofSize: 13)
        let headerFont = NSFont.systemFont(ofSize: 13, weight: .semibold)

        let bodyParagraph = NSMutableParagraphStyle()
        bodyParagraph.paragraphSpacing = 4
        bodyParagraph.lineHeightMultiple = 1.25

        let headerParagraph = NSMutableParagraphStyle()
        headerParagraph.paragraphSpacingBefore = 10
        headerParagraph.paragraphSpacing = 4
        headerParagraph.lineHeightMultiple = 1.25

        let output = NSMutableAttributedString()
        let lines = text.components(separatedBy: .newlines)

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            let isNumbered = trimmed.range(of: #"^\d+\.\s"#, options: .regularExpression) != nil
            let isHeader = trimmed.hasSuffix(":") && !isNumbered

            let attributes: [NSAttributedString.Key: Any]
            if isHeader {
                attributes = [
                    .font: headerFont,
                    .foregroundColor: NSColor.secondaryLabelColor,
                    .paragraphStyle: index == 0 ? bodyParagraph : headerParagraph,
                ]
            } else {
                attributes = [
                    .font: bodyFont,
                    .foregroundColor: NSColor.labelColor,
                    .paragraphStyle: bodyParagraph,
                ]
            }

            if output.length > 0 {
                output.append(NSAttributedString(string: "\n"))
            }
            output.append(NSAttributedString(string: trimmed, attributes: attributes))
        }

        return output
    }
}
