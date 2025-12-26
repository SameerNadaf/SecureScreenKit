//
//  RecordingOverlayModifier.swift
//  SecureScreenKit
//
//  View modifier for recording protection overlay
//

import SwiftUI

/// View modifier that adds recording protection overlay to any view.
///
/// This modifier wraps the view in protection logic that shows an overlay
/// when screen recording is detected, based on the specified policy.
///
/// ## Usage
/// Apply protection using the `.recordingProtected()` modifier:
/// ```swift
/// Text("Secret Data")
///     .recordingProtected(policy: .obscure(style: .blur(radius: 20)))
/// ```
public struct RecordingOverlayModifier: ViewModifier {
    
    // MARK: - Properties
    
    private let policy: CapturePolicy
    private let condition: (any CaptureCondition)?
    private let screenIdentifier: String?
    private let userRole: String?
    
    // MARK: - Initialization
    
    /// Creates a recording overlay modifier.
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
        RecordingOverlayContainer(
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
    
    /// Protects this view with an overlay during screen recording.
    ///
    /// When screen recording is detected, an overlay matching the policy
    /// will be shown over this view.
    ///
    /// ## Example Usage
    ///
    /// ### Default Policy
    /// ```swift
    /// SensitiveView()
    ///     .recordingProtected()
    /// ```
    ///
    /// ### Custom Policy
    /// ```swift
    /// BankingView()
    ///     .recordingProtected(policy: .block(reason: "Banking data protected"))
    /// ```
    ///
    /// ### Conditional Protection
    /// ```swift
    /// PatientRecords()
    ///     .recordingProtected(
    ///         policy: .obscure(style: .blur(radius: 30)),
    ///         condition: RecordingOnlyCondition()
    ///     )
    /// ```
    ///
    /// - Parameters:
    ///   - policy: The protection policy.
    ///   - condition: Optional condition for conditional protection.
    /// - Returns: A view with recording protection applied.
    @MainActor
    func recordingProtected(
        policy: CapturePolicy,
        condition: (any CaptureCondition)? = nil
    ) -> some View {
        modifier(RecordingOverlayModifier(
            policy: policy,
            condition: condition
        ))
    }
    
    /// Protects this view using the default policy during screen recording.
    ///
    /// - Returns: A view with recording protection applied.
    @MainActor
    func recordingProtected() -> some View {
        modifier(RecordingOverlayModifier(
            policy: SecureScreenConfiguration.shared.defaultPolicy,
            condition: nil
        ))
    }
    
    /// Protects this view with full context configuration during recording.
    ///
    /// - Parameters:
    ///   - policy: The protection policy.
    ///   - condition: Optional condition for conditional protection.
    ///   - screenIdentifier: Identifier for this screen in policy context.
    ///   - userRole: User role for role-based policies.
    /// - Returns: A view with recording protection applied.
    func recordingProtected(
        policy: CapturePolicy,
        condition: (any CaptureCondition)?,
        screenIdentifier: String?,
        userRole: String?
    ) -> some View {
        modifier(RecordingOverlayModifier(
            policy: policy,
            condition: condition,
            screenIdentifier: screenIdentifier,
            userRole: userRole
        ))
    }
}

// MARK: - Deprecated Aliases for Backward Compatibility

@available(*, deprecated, renamed: "RecordingOverlayModifier")
public typealias SecureViewModifier = RecordingOverlayModifier

public extension View {
    @available(*, deprecated, renamed: "recordingProtected(policy:condition:)")
    @MainActor
    func secureContent(
        policy: CapturePolicy,
        condition: (any CaptureCondition)? = nil
    ) -> some View {
        recordingProtected(policy: policy, condition: condition)
    }
    
    @available(*, deprecated, renamed: "recordingProtected()")
    @MainActor
    func secureContent() -> some View {
        recordingProtected()
    }
    
    @available(*, deprecated, renamed: "recordingProtected(policy:condition:screenIdentifier:userRole:)")
    func secureContent(
        policy: CapturePolicy,
        condition: (any CaptureCondition)?,
        screenIdentifier: String?,
        userRole: String?
    ) -> some View {
        recordingProtected(
            policy: policy,
            condition: condition,
            screenIdentifier: screenIdentifier,
            userRole: userRole
        )
    }
}
