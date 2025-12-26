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
/// // Using SecureContainer
/// SecureContainer(policy: .block(reason: "Protected")) {
///     SensitiveDataView()
/// }
///
/// // Using view modifier
/// SensitiveView()
///     .secureContent(policy: .obscure(style: .blackout))
/// ```
///
/// ### UIKit Usage
/// ```swift
/// // Using SecureViewController
/// class MyViewController: SecureViewController {
///     override func viewDidLoad() {
///         super.viewDidLoad()
///         policy = .obscure(style: .blur(radius: 25))
///     }
/// }
///
/// // Using extension
/// myViewController.secure(policy: .block(reason: "Protected"))
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

// The following types are public:
// - SecureScreenConfiguration
// - CapturePolicy
// - ObscureStyle
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
// - CaptureContext
// - CaptureState
// - SecureContainer
// - SecureContentView (screenshot-proof content using secure text field trick)
// - SecureViewModifier (via .secureContent modifier)
// - View.screenshotProof() (makes content hidden from screenshots)
// - SecureHostingController
// - SecureViewController
// - SecureUIView (UIKit screenshot-proof container)
// - ViolationHandler (protocol)
// - DefaultViolationHandler
// - BlockViolationHandler

