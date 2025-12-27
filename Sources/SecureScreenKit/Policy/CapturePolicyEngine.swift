//
//  CapturePolicyEngine.swift
//  SecureScreenKit
//
//  Enterprise-grade screen capture protection for iOS
//

import UIKit

/// Central engine for resolving capture protection policies.
///
/// The `CapturePolicyEngine` is the single source of truth for all protection
/// decisions. It evaluates policies against conditions and current context
/// to determine what action should be taken.
///
/// ## Usage
/// All protection decisions MUST flow through this engine. UI components
/// should never make protection decisions directly.
///
/// ```swift
/// let engine = CapturePolicyEngine.shared
/// let action = engine.resolvePolicy(
///     .obscure(style: .blur(radius: 20)),
///     condition: myCondition,
///     context: currentContext
/// )
/// // Apply action based on result
/// ```
@MainActor
internal final class CapturePolicyEngine {
    
    // MARK: - Singleton
    
    /// Shared policy engine instance.
    static let shared = CapturePolicyEngine()
    
    // MARK: - Properties
    
    /// Reference to the capture monitor for state information.
    private let monitor: CaptureMonitor
    
    // MARK: - Initialization
    
    private init() {
        self.monitor = CaptureMonitor.shared
    }
    
    // MARK: - Policy Resolution
    
    /// Resolves what action should be taken based on policy, condition, and context.
    ///
    /// This is the primary entry point for protection decisions. It considers:
    /// 1. Condition evaluation
    /// 2. Current capture state
    /// 3. Policy requirements
    ///
    /// - Note: Component-level protection works independently of global `isProtectionEnabled` flag.
    ///   The global flag only affects `shouldProtectWithDefaultPolicy()`.
    ///
    /// - Parameters:
    ///   - policy: The protection policy to evaluate.
    ///   - condition: Optional condition for conditional protection.
    ///   - context: The current capture context.
    /// - Returns: The resolved action to take.
    func resolvePolicy(
        _ policy: CapturePolicy,
        condition: (any CaptureCondition)?,
        context: CaptureContext
    ) -> ResolvedAction {
        
        // If policy is always allow, no action needed
        guard policy.requiresProtection else {
            return .none
        }
        
        // Evaluate condition if provided
        if let condition = condition {
            guard condition.shouldProtect(context: context) else {
                return .none
            }
        } else {
            // No condition specified - protect if capture is active
            guard context.isScreenCaptured || context.isScreenshotEvent else {
                return .none
            }
        }
        
        // Return the appropriate action based on policy
        return actionForPolicy(policy)
    }
    
    /// Resolves policy using current system context.
    ///
    /// Convenience method that creates context automatically.
    ///
    /// - Parameters:
    ///   - policy: The protection policy to evaluate.
    ///   - condition: Optional condition for conditional protection.
    ///   - screenIdentifier: Optional screen identifier.
    ///   - userRole: Optional user role.
    /// - Returns: The resolved action to take.
    func resolvePolicy(
        _ policy: CapturePolicy,
        condition: (any CaptureCondition)?,
        screenIdentifier: String? = nil,
        userRole: String? = nil
    ) -> ResolvedAction {
        let context = monitor.createContext(
            screenIdentifier: screenIdentifier,
            userRole: userRole
        )
        return resolvePolicy(policy, condition: condition, context: context)
    }
    
    /// Checks if protection should currently be active based on default policy.
    ///
    /// - Returns: `true` if protection should be active.
    func shouldProtectWithDefaultPolicy() -> Bool {
        guard SecureScreenConfiguration.shared.isProtectionEnabled else {
            return false
        }
        
        let defaultPolicy = SecureScreenConfiguration.shared.defaultPolicy
        guard defaultPolicy.requiresProtection else {
            return false
        }
        
        return monitor.isRecording || monitor.captureState == .screenshotTaken
    }
    
    // MARK: - Private Methods
    
    private func actionForPolicy(_ policy: CapturePolicy) -> ResolvedAction {
        switch policy {
        case .allow:
            return .none
            
        case .obscure(let style):
            return .obscure(style)
            
        case .block(let reason):
            return .block(reason)
            
        case .logout:
            return .logout
        }
    }
}

// MARK: - ResolvedAction

/// Represents the resolved action to take based on policy evaluation.
internal enum ResolvedAction: Equatable {
    
    /// No protective action needed.
    case none
    
    /// Obscure content with the specified style.
    case obscure(ObscureStyle)
    
    /// Block content with optional reason.
    case block(String?)
    
    /// Trigger logout/session invalidation.
    case logout
    
    /// Whether any action should be taken.
    var requiresAction: Bool {
        switch self {
        case .none:
            return false
        case .obscure, .block, .logout:
            return true
        }
    }
}
