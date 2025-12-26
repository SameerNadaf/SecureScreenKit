//
//  CapturePolicy.swift
//  SecureScreenKit
//
//  Enterprise-grade screen capture protection for iOS
//

import UIKit

/// Defines how content should be protected when screen capture is detected.
///
/// This enum represents the available protection policies that can be applied
/// to views or globally when screen recording or screenshots are detected.
///
/// ## Example Usage
/// ```swift
/// // Apply blur protection
/// SecureContainer(policy: .obscure(style: .blur(radius: 20))) {
///     SensitiveContentView()
/// }
///
/// // Block with message
/// SecureContainer(policy: .block(reason: "Screen recording not allowed")) {
///     BankingView()
/// }
/// ```
public enum CapturePolicy: Equatable, Sendable {
    
    /// Allow content to be visible during capture.
    ///
    /// Use this for non-sensitive content or when the user has been
    /// explicitly granted permission.
    case allow
    
    /// Obscure content with the specified style.
    ///
    /// The content remains in the view hierarchy but is visually hidden.
    /// - Parameter style: The visual style used to obscure content.
    case obscure(style: ObscureStyle)
    
    /// Block content entirely with an optional reason message.
    ///
    /// Displays a blocking overlay that completely hides the content.
    /// - Parameter reason: Optional message explaining why content is blocked.
    case block(reason: String?)
    
    /// Trigger a logout or session invalidation.
    ///
    /// Use for high-security scenarios where any capture attempt
    /// should end the user's session.
    case logout
    
    /// Whether this policy requires any protective action.
    public var requiresProtection: Bool {
        switch self {
        case .allow:
            return false
        case .obscure, .block, .logout:
            return true
        }
    }
}

// MARK: - ObscureStyle

/// Visual styles for obscuring protected content.
///
/// These styles define how content should be hidden when capture is detected.
public enum ObscureStyle: Equatable, Sendable {
    
    /// Apply a Gaussian blur effect.
    ///
    /// - Parameter radius: The blur radius. Higher values create stronger blur.
    ///   Recommended range: 10-30 for effective obscuring.
    case blur(radius: CGFloat)
    
    /// Completely black out the content.
    ///
    /// Displays an opaque black overlay over the content.
    case blackout
    
    /// Use a custom view for obscuring.
    ///
    /// - Parameter viewProvider: A closure that creates the custom overlay view.
    ///
    /// - Important: The closure must be able to create a new view each time
    ///   it is called, as the view may be recreated during lifecycle events.
    case custom(@Sendable () -> UIView)
    
    // MARK: - Equatable Conformance
    
    public static func == (lhs: ObscureStyle, rhs: ObscureStyle) -> Bool {
        switch (lhs, rhs) {
        case (.blur(let lRadius), .blur(let rRadius)):
            return lRadius == rRadius
        case (.blackout, .blackout):
            return true
        case (.custom, .custom):
            // Custom views cannot be meaningfully compared
            return false
        default:
            return false
        }
    }
}

// MARK: - Default Policy Extensions

extension CapturePolicy {
    
    /// Default blur policy with standard radius.
    public static var defaultBlur: CapturePolicy {
        .obscure(style: .blur(radius: 20))
    }
    
    /// Default blackout policy.
    public static var defaultBlackout: CapturePolicy {
        .obscure(style: .blackout)
    }
    
    /// Default block policy with standard message.
    public static var defaultBlock: CapturePolicy {
        .block(reason: "This content cannot be captured")
    }
}
