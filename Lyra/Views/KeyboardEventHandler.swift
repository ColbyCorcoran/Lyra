//
//  KeyboardEventHandler.swift
//  Lyra
//
//  UIViewController wrapper for handling keyboard events in SwiftUI
//

import SwiftUI
import UIKit

/// A UIViewControllerRepresentable that handles keyboard events
struct KeyboardEventHandler: UIViewControllerRepresentable {
    let onKeyCommand: (String, UIKeyModifierFlags) -> Void

    func makeUIViewController(context: Context) -> KeyboardViewController {
        let controller = KeyboardViewController()
        controller.onKeyCommand = onKeyCommand
        return controller
    }

    func updateUIViewController(_ uiViewController: KeyboardViewController, context: Context) {
        uiViewController.onKeyCommand = onKeyCommand
    }
}

/// Custom UIViewController that captures keyboard events
class KeyboardViewController: UIViewController {
    var onKeyCommand: ((String, UIKeyModifierFlags) -> Void)?

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override var keyCommands: [UIKeyCommand]? {
        var commands: [UIKeyCommand] = []

        // Arrow keys
        commands.append(UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: [], action: #selector(handleKeyCommand(_:))))
        commands.append(UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(handleKeyCommand(_:))))
        commands.append(UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(handleKeyCommand(_:))))
        commands.append(UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(handleKeyCommand(_:))))

        // Page Up/Down
        commands.append(UIKeyCommand(input: UIKeyCommand.inputPageUp, modifierFlags: [], action: #selector(handleKeyCommand(_:))))
        commands.append(UIKeyCommand(input: UIKeyCommand.inputPageDown, modifierFlags: [], action: #selector(handleKeyCommand(_:))))

        // Space and Return
        commands.append(UIKeyCommand(input: " ", modifierFlags: [], action: #selector(handleKeyCommand(_:))))
        commands.append(UIKeyCommand(input: "\r", modifierFlags: [], action: #selector(handleKeyCommand(_:))))

        // Single letter keys (for shortcuts)
        let letters = ["t", "T", "m", "M", "a", "A", "d", "D"]
        for letter in letters {
            commands.append(UIKeyCommand(input: letter, modifierFlags: [], action: #selector(handleKeyCommand(_:))))
        }

        // Command shortcuts
        let commandLetters = ["f", "F", "n", "N", "e", "E", "p", "P", "s", "S", "l", "L"]
        for letter in commandLetters {
            commands.append(UIKeyCommand(input: letter, modifierFlags: .command, action: #selector(handleKeyCommand(_:))))
        }

        // Command+Shift shortcuts
        commands.append(UIKeyCommand(input: "s", modifierFlags: [.command, .shift], action: #selector(handleKeyCommand(_:))))
        commands.append(UIKeyCommand(input: "S", modifierFlags: [.command, .shift], action: #selector(handleKeyCommand(_:))))

        // Disable system behavior for these keys
        commands.forEach { $0.wantsPriorityOverSystemBehavior = true }

        return commands
    }

    @objc private func handleKeyCommand(_ sender: UIKeyCommand) {
        guard let input = sender.input else { return }
        onKeyCommand?(input, sender.modifierFlags)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }
}
