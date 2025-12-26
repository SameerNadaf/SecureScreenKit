//
//  CaptureContext.swift
//  SecureScreenKit
//
//  Enterprise-grade screen capture protection for iOS
//

import UIKit

/// Context information provided to policy conditions for evaluation.
///
/// This struct provides all relevant runtime information needed to make
/// policy decisions about content protection. It is passed to `CaptureCondition`
/// implementations for evaluation.
///
/// ## Example Usage
/// ```swift
/// struct AdminExemptCondition: CaptureCondition {
///     func shouldProtect(context: CaptureContext) -> Bool {
///         // Admins are exempt from protection
///         return context.userRole != "admin"
///     }
/// }
/// ```
public struct CaptureContext: Sendable {
    
    /// Whether screen recording/mirroring is currently active.
    ///
    /// This is derived from `UIScreen.main.isCaptured`.
    public let isScreenCaptured: Bool
    
    /// Whether a screenshot event just occurred.
    ///
    /// This flag is `true` immediately after a screenshot notification
    /// and should be treated as transient.
    public let isScreenshotEvent: Bool
    
    /// The current application lifecycle state.
    ///
    /// Useful for policies that behave differently in foreground vs background.
    public let appState: UIApplication.State
    
    /// Optional identifier for the current screen or view.
    ///
    /// Can be used to apply different policies to different screens.
    public let screenIdentifier: String?
    
    /// Optional role identifier for the current user.
    ///
    /// Useful for role-based protection policies (e.g., exempt admins).
    public let userRole: String?
    
    /// Creates a new capture context.
    ///
    /// - Parameters:
    ///   - isScreenCaptured: Whether screen capture is active.
    ///   - isScreenshotEvent: Whether a screenshot just occurred.
    ///   - appState: Current application state.
    ///   - screenIdentifier: Optional screen identifier.
    ///   - userRole: Optional user role.
    public init(
        isScreenCaptured: Bool,
        isScreenshotEvent: Bool,
        appState: UIApplication.State,
        screenIdentifier: String? = nil,
        userRole: String? = nil
    ) {
        self.isScreenCaptured = isScreenCaptured
        self.isScreenshotEvent = isScreenshotEvent
        self.appState = appState
        self.screenIdentifier = screenIdentifier
        self.userRole = userRole
    }
    
    /// Creates a context representing the current system state.
    ///
    /// - Parameters:
    ///   - screenIdentifier: Optional screen identifier.
    ///   - userRole: Optional user role.
    /// - Returns: A context reflecting current capture and app state.
    @MainActor
    public static func current(
        screenIdentifier: String? = nil,
        userRole: String? = nil
    ) -> CaptureContext {
        return CaptureContext(
            isScreenCaptured: UIScreen.main.isCaptured,
            isScreenshotEvent: false,
            appState: UIApplication.shared.applicationState,
            screenIdentifier: screenIdentifier,
            userRole: userRole
        )
    }
}

// MARK: - UIApplication.State Sendable Conformance

extension UIApplication.State: @retroactive @unchecked Sendable {}
