//
//  SecureScreenKit.swift
//  SecureScreenKit
//
//  Enterprise-grade screen capture protection for iOS
//
//  Copyright © 2024. All rights reserved.
//

/// # SecureScreenKit
///
/// Enterprise-grade screen capture protection for iOS applications.
///
/// ## Overview
///
/// SecureScreenKit provides detection and response capabilities for screen
/// capture events on iOS. It allows you to protect sensitive content by
/// obscuring or hiding views when screen recording or screenshots are detected.
///
/// ## Features
///
/// - **Screen Recording Detection**: Real-time detection of iOS screen recording,
///   AirPlay mirroring, and other capture methods.
/// - **Screenshot Detection**: Notification when screenshots are taken.
/// - **Policy-Based Protection**: Flexible policies for different protection needs.
/// - **Conditional Protection**: Role-based, screen-based, and custom conditions.
/// - **SwiftUI & UIKit Support**: Full support for both frameworks.
/// - **Global Shield**: System-wide overlay for immediate protection.
///
/// ## Platform Limitations
///
/// > Important: iOS does not allow apps to prevent screenshots or screen recordings.
/// > SecureScreenKit can only **detect** these events and **respond** by obscuring content.
///
/// ## Protection Types
///
/// | Type | SwiftUI | UIKit | Modifier |
/// |------|---------|-------|----------|
/// | **Screenshot Only** | `ScreenshotProofView` | `ScreenshotProofUIView` | `.screenshotProtected()` |
/// | **Recording Only** | `RecordingOverlayContainer` | `RecordingOverlayView` | `.recordingProtected()` |
/// | **Complete (Both)** | `ScreenProtectedView` | `ScreenProtectedUIView` | `.screenProtected()` |
///
/// ## Quick Start
///
/// ### Configuration
/// ```swift
/// // In AppDelegate or early initialization
/// SecureScreenConfiguration.shared.configure(
///     enabled: true,
///     defaultPolicy: .obscure(style: .blur(radius: 20))
/// )
/// SecureScreenConfiguration.shared.startProtection()
/// ```
///
/// ### SwiftUI Usage
/// ```swift
/// // Complete protection (screenshot + recording)
/// ScreenProtectedView {
///     SensitiveDataView()
/// }
///
/// // Using view modifier
/// SensitiveView()
///     .screenProtected()
///
/// // Recording overlay only
/// RecordingOverlayContainer(policy: .block(reason: "Protected")) {
///     SensitiveView()
/// }
/// ```
///
/// ### UIKit Usage
/// ```swift
/// // Subclass for recording protection
/// class MyViewController: RecordingProtectedViewController {
///     override func viewDidLoad() {
///         super.viewDidLoad()
///         policy = .obscure(style: .blur(radius: 25))
///     }
/// }
///
/// // Or use extensions
/// myViewController.protectFromRecording(policy: .block(reason: "Protected"))
/// ```
///
/// ## Violation Handling
/// ```swift
/// class MyHandler: ViolationHandler {
///     func didStartScreenCapture() {
///         // Log or take action
///     }
///     func screenshotTaken() {
///         // Screenshot already captured - log only
///     }
/// }
/// SecureScreenConfiguration.shared.violationHandler = MyHandler()
/// ```

// MARK: - Public Exports

// Configuration
@_exported import struct Foundation.URL

// Re-export public types for cleaner imports
// Users can simply `import SecureScreenKit` to access all public API

// Configuration & Violation Handling:
// - SecureScreenConfiguration
// - ViolationHandler (protocol)
// - DefaultViolationHandler
// - BlockViolationHandler

// Core Types:
// - CapturePolicy (.allow, .obscure, .block, .logout)
// - ObscureStyle (.blur, .blackout, .custom)
// - CaptureState (.idle, .recording, .screenshotTaken)
// - CaptureContext

// Conditions:
// - CaptureCondition (protocol)
// - AlwaysProtectCondition
// - NeverProtectCondition
// - RecordingOnlyCondition
// - ScreenshotOnlyCondition
// - RoleBasedCondition
// - ScreenBasedCondition
// - CompositeAndCondition
// - CompositeOrCondition
// - AnyCaptureCondition

// SwiftUI Components:
// - ScreenshotProofView (hides from screenshots)
// - RecordingOverlayContainer (overlay during recording)
// - ScreenProtectedView (complete protection - both)
// - RecordingProtectedHostingController

// SwiftUI View Modifiers:
// - .screenshotProtected()
// - .recordingProtected()
// - .screenProtected()

// UIKit Components:
// - ScreenshotProofUIView (hides from screenshots)
// - RecordingOverlayView (overlay during recording)
// - ScreenProtectedUIView (complete protection - both)
// - RecordingProtectedViewController

// UIKit Extensions:
// - UIView.enableRecordingProtection(policy:)
// - UIView.wrapInScreenshotProofContainer()
// - UIViewController.protectFromRecording(policy:)
