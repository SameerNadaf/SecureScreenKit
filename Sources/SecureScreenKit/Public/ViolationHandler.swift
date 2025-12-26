//
//  ViolationHandler.swift
//  SecureScreenKit
//
//  Enterprise-grade screen capture protection for iOS
//

import Foundation

/// Protocol for handling screen capture violation events.
///
/// Implement this protocol to receive callbacks when capture events occur.
/// Use these callbacks for logging, analytics, session management, or
/// custom business logic.
///
/// ## Example Implementation
/// ```swift
/// class MyViolationHandler: ViolationHandler {
///     func didStartScreenCapture() {
///         Analytics.log("screen_recording_started")
///         // Optionally invalidate session
///     }
///
///     func didStopScreenCapture() {
///         Analytics.log("screen_recording_stopped")
///     }
///
///     func screenshotTaken() {
///         Analytics.log("screenshot_taken")
///         // Note: Screenshot already captured at this point
///     }
/// }
///
/// // Register the handler
/// SecureScreenConfiguration.shared.violationHandler = MyViolationHandler()
/// ```
///
/// - Important: These callbacks are informational. The capture event
///   has already occurred when the callback fires.
public protocol ViolationHandler: AnyObject, Sendable {
    
    /// Called when screen recording or mirroring starts.
    ///
    /// This is triggered by:
    /// - iOS screen recording
    /// - AirPlay mirroring
    /// - QuickTime recording via cable
    /// - Third-party screen capture apps
    ///
    /// - Note: Called on the main thread.
    @MainActor
    func didStartScreenCapture()
    
    /// Called when screen recording or mirroring stops.
    ///
    /// - Note: Called on the main thread.
    @MainActor
    func didStopScreenCapture()
    
    /// Called when a screenshot is taken.
    ///
    /// - Important: The screenshot has already been captured when this fires.
    ///   You cannot prevent or modify the screenshot.
    ///
    /// Use this for:
    /// - Logging/analytics
    /// - User notification
    /// - Session invalidation (if required by policy)
    ///
    /// - Note: Called on the main thread.
    @MainActor
    func screenshotTaken()
}

// MARK: - Default Implementations

public extension ViolationHandler {
    
    /// Default no-op implementation.
    @MainActor
    func didStartScreenCapture() {
        // Default: no action
    }
    
    /// Default no-op implementation.
    @MainActor
    func didStopScreenCapture() {
        // Default: no action
    }
    
    /// Default no-op implementation.
    @MainActor
    func screenshotTaken() {
        // Default: no action
    }
}

// MARK: - Default Handler

/// A default violation handler that logs events to console.
///
/// Use this for development and debugging:
/// ```swift
/// SecureScreenConfiguration.shared.violationHandler = DefaultViolationHandler()
/// ```
@MainActor
public final class DefaultViolationHandler: ViolationHandler, @unchecked Sendable {
    
    /// Creates a default violation handler.
    public init() {}
    
    public func didStartScreenCapture() {
        print("[SecureScreenKit] Screen capture started")
    }
    
    public func didStopScreenCapture() {
        print("[SecureScreenKit] Screen capture stopped")
    }
    
    public func screenshotTaken() {
        print("[SecureScreenKit] Screenshot taken")
    }
}

// MARK: - Block-based Handler

/// A violation handler that uses closures for callbacks.
///
/// Useful when you don't want to create a separate class:
/// ```swift
/// let handler = BlockViolationHandler(
///     onCaptureStarted: { print("Recording!") },
///     onScreenshot: { Analytics.log("screenshot") }
/// )
/// SecureScreenConfiguration.shared.violationHandler = handler
/// ```
@MainActor
public final class BlockViolationHandler: ViolationHandler, @unchecked Sendable {
    
    private let onCaptureStarted: (@MainActor () -> Void)?
    private let onCaptureStopped: (@MainActor () -> Void)?
    private let onScreenshot: (@MainActor () -> Void)?
    
    /// Creates a block-based violation handler.
    ///
    /// - Parameters:
    ///   - onCaptureStarted: Called when capture starts.
    ///   - onCaptureStopped: Called when capture stops.
    ///   - onScreenshot: Called when screenshot is taken.
    public init(
        onCaptureStarted: (@MainActor () -> Void)? = nil,
        onCaptureStopped: (@MainActor () -> Void)? = nil,
        onScreenshot: (@MainActor () -> Void)? = nil
    ) {
        self.onCaptureStarted = onCaptureStarted
        self.onCaptureStopped = onCaptureStopped
        self.onScreenshot = onScreenshot
    }
    
    public func didStartScreenCapture() {
        onCaptureStarted?()
    }
    
    public func didStopScreenCapture() {
        onCaptureStopped?()
    }
    
    public func screenshotTaken() {
        onScreenshot?()
    }
}
