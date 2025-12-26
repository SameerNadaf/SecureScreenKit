//
//  SecureViewModifier.swift
//  SecureScreenKit
//
//  Enterprise-grade screen capture protection for iOS
//

import SwiftUI

/// View modifier that adds screen capture protection to any view.
///
/// This modifier wraps the view in protection logic that responds to
/// screen capture events based on the specified policy and conditions.
///
/// ## Usage
/// Apply protection using the `.secureContent()` modifier:
/// ```swift
/// Text("Secret Data")
///     .secureContent(policy: .obscure(style: .blur(radius: 20)))
/// ```
public struct SecureViewModifier: ViewModifier {
    
    // MARK: - Properties
    
    private let policy: CapturePolicy
    private let condition: (any CaptureCondition)?
    private let screenIdentifier: String?
    private let userRole: String?
    
    // MARK: - Initialization
    
    /// Creates a secure view modifier.
    ///
    /// - Parameters:
    ///   - policy: The protection policy to apply.
    ///   - condition: Optional condition for conditional protection.
    ///   - screenIdentifier: Optional screen identifier for context.
    ///   - userRole: Optional user role for context.
    public init(
        policy: CapturePolicy,
        condition: (any CaptureCondition)? = nil,
        screenIdentifier: String? = nil,
        userRole: String? = nil
    ) {
        self.policy = policy
        self.condition = condition
        self.screenIdentifier = screenIdentifier
        self.userRole = userRole
    }
    
    // MARK: - ViewModifier
    
    public func body(content: Content) -> some View {
        SecureContainer(
            policy: policy,
            condition: condition,
            screenIdentifier: screenIdentifier,
            userRole: userRole
        ) {
            content
        }
    }
}

// MARK: - View Extension

public extension View {
    
    /// Protects this view's content from screen capture.
    ///
    /// When screen capture is detected, the view will be obscured or blocked
    /// according to the specified policy.
    ///
    /// ## Example Usage
    ///
    /// ### Default Policy
    /// ```swift
    /// SensitiveView()
    ///     .secureContent()
    /// ```
    ///
    /// ### Custom Policy
    /// ```swift
    /// BankingView()
    ///     .secureContent(policy: .block(reason: "Banking data protected"))
    /// ```
    ///
    /// ### Conditional Protection
    /// ```swift
    /// PatientRecords()
    ///     .secureContent(
    ///         policy: .obscure(style: .blur(radius: 30)),
    ///         condition: RecordingOnlyCondition()
    ///     )
    /// ```
    ///
    /// - Parameters:
    ///   - policy: The protection policy.
    ///   - condition: Optional condition for conditional protection.
    /// - Returns: A view with screen capture protection applied.
    @MainActor
    func secureContent(
        policy: CapturePolicy,
        condition: (any CaptureCondition)? = nil
    ) -> some View {
        modifier(SecureViewModifier(
            policy: policy,
            condition: condition
        ))
    }
    
    /// Protects this view's content using the default policy.
    ///
    /// - Returns: A view with screen capture protection applied.
    @MainActor
    func secureContent() -> some View {
        modifier(SecureViewModifier(
            policy: SecureScreenConfiguration.shared.defaultPolicy,
            condition: nil
        ))
    }
    
    /// Protects this view's content with full context configuration.
    ///
    /// - Parameters:
    ///   - policy: The protection policy.
    ///   - condition: Optional condition for conditional protection.
    ///   - screenIdentifier: Identifier for this screen in policy context.
    ///   - userRole: User role for role-based policies.
    /// - Returns: A view with screen capture protection applied.
    func secureContent(
        policy: CapturePolicy,
        condition: (any CaptureCondition)?,
        screenIdentifier: String?,
        userRole: String?
    ) -> some View {
        modifier(SecureViewModifier(
            policy: policy,
            condition: condition,
            screenIdentifier: screenIdentifier,
            userRole: userRole
        ))
    }
}
