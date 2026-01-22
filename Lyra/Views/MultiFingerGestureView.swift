//
//  MultiFingerGestureView.swift
//  Lyra
//
//  View for handling multi-finger gesture recognition
//

import SwiftUI
import UIKit

struct MultiFingerGestureView: UIViewRepresentable {
    let onLongPress: (CGPoint) -> Void
    let onTwoFingerSwipeUp: () -> Void
    let onTwoFingerSwipeDown: () -> Void
    let onTwoFingerTap: () -> Void
    let onThreeFingerTap: () -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear

        // Long press gesture (single finger)
        let longPress = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
        longPress.minimumPressDuration = 0.5
        view.addGestureRecognizer(longPress)

        // Two-finger swipe up
        let twoFingerSwipeUp = UISwipeGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTwoFingerSwipeUp))
        twoFingerSwipeUp.direction = .up
        twoFingerSwipeUp.numberOfTouchesRequired = 2
        view.addGestureRecognizer(twoFingerSwipeUp)

        // Two-finger swipe down
        let twoFingerSwipeDown = UISwipeGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTwoFingerSwipeDown))
        twoFingerSwipeDown.direction = .down
        twoFingerSwipeDown.numberOfTouchesRequired = 2
        view.addGestureRecognizer(twoFingerSwipeDown)

        // Two-finger tap
        let twoFingerTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTwoFingerTap))
        twoFingerTap.numberOfTouchesRequired = 2
        view.addGestureRecognizer(twoFingerTap)

        // Three-finger tap
        let threeFingerTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleThreeFingerTap))
        threeFingerTap.numberOfTouchesRequired = 3
        view.addGestureRecognizer(threeFingerTap)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onLongPress = onLongPress
        context.coordinator.onTwoFingerSwipeUp = onTwoFingerSwipeUp
        context.coordinator.onTwoFingerSwipeDown = onTwoFingerSwipeDown
        context.coordinator.onTwoFingerTap = onTwoFingerTap
        context.coordinator.onThreeFingerTap = onThreeFingerTap
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onLongPress: onLongPress,
            onTwoFingerSwipeUp: onTwoFingerSwipeUp,
            onTwoFingerSwipeDown: onTwoFingerSwipeDown,
            onTwoFingerTap: onTwoFingerTap,
            onThreeFingerTap: onThreeFingerTap
        )
    }

    class Coordinator: NSObject {
        var onLongPress: (CGPoint) -> Void
        var onTwoFingerSwipeUp: () -> Void
        var onTwoFingerSwipeDown: () -> Void
        var onTwoFingerTap: () -> Void
        var onThreeFingerTap: () -> Void

        init(
            onLongPress: @escaping (CGPoint) -> Void,
            onTwoFingerSwipeUp: @escaping () -> Void,
            onTwoFingerSwipeDown: @escaping () -> Void,
            onTwoFingerTap: @escaping () -> Void,
            onThreeFingerTap: @escaping () -> Void
        ) {
            self.onLongPress = onLongPress
            self.onTwoFingerSwipeUp = onTwoFingerSwipeUp
            self.onTwoFingerSwipeDown = onTwoFingerSwipeDown
            self.onTwoFingerTap = onTwoFingerTap
            self.onThreeFingerTap = onThreeFingerTap
        }

        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            if gesture.state == .began {
                let location = gesture.location(in: gesture.view)
                onLongPress(location)
            }
        }

        @objc func handleTwoFingerSwipeUp() {
            onTwoFingerSwipeUp()
        }

        @objc func handleTwoFingerSwipeDown() {
            onTwoFingerSwipeDown()
        }

        @objc func handleTwoFingerTap() {
            onTwoFingerTap()
        }

        @objc func handleThreeFingerTap() {
            onThreeFingerTap()
        }
    }
}
