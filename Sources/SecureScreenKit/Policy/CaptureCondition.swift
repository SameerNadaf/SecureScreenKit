//
//  CaptureCondition.swift
//  SecureScreenKit
//
//  Enterprise-grade screen capture protection for iOS
//

import Foundation

/// Protocol for defining conditional protection logic.
///
/// Implement this protocol to create custom conditions that determine
/// when content should be protected based on runtime context.
///
/// ## Example Implementations
///
/// ### Role-Based Protection
/// ```swift
/// struct NonAdminCondition: CaptureCondition {
///     func shouldProtect(context: CaptureContext) -> Bool {
///         // Only protect for non-admin users
///         return context.userRole != "admin"
///     }
/// }
/// ```
///
/// ### Screen-Specific Protection
/// ```swift
/// struct SensitiveScreenCondition: CaptureCondition {
///     let sensitiveScreens = ["banking", "medical", "passwords"]
///
///     func shouldProtect(context: CaptureContext) -> Bool {
///         guard let screenId = context.screenIdentifier else {
///             return true // Default to protected
///         }
///         return sensitiveScreens.contains(screenId)
///     }
/// }
/// ```
///
/// ### Recording-Only Protection
/// ```swift
/// struct RecordingOnlyCondition: CaptureCondition {
///     func shouldProtect(context: CaptureContext) -> Bool {
///         // Only protect during active recording, not screenshots
///         return context.isScreenCaptured && !context.isScreenshotEvent
///     }
/// }
/// ```
public protocol CaptureCondition: Sendable {
    
    /// Evaluates whether protection should be applied based on context.
    ///
    /// - Parameter context: The current capture context containing
    ///   information about capture state, app state, and user context.
    /// - Returns: `true` if protection should be applied, `false` otherwise.
    func shouldProtect(context: CaptureContext) -> Bool
}

// MARK: - Built-in Conditions

/// Always applies protection when capture is detected.
public struct AlwaysProtectCondition: CaptureCondition {
    
    public init() {}
    
    public func shouldProtect(context: CaptureContext) -> Bool {
        return context.isScreenCaptured || context.isScreenshotEvent
    }
}

/// Never applies protection (effectively disables it).
public struct NeverProtectCondition: CaptureCondition {
    
    public init() {}
    
    public func shouldProtect(context: CaptureContext) -> Bool {
        return false
    }
}

/// Protects only during active screen recording, not screenshots.
public struct RecordingOnlyCondition: CaptureCondition {
    
    public init() {}
    
    public func shouldProtect(context: CaptureContext) -> Bool {
        return context.isScreenCaptured
    }
}

/// Protects only when a screenshot is taken, not during recording.
public struct ScreenshotOnlyCondition: CaptureCondition {
    
    public init() {}
    
    public func shouldProtect(context: CaptureContext) -> Bool {
        return context.isScreenshotEvent
    }
}

/// Protects based on user role.
public struct RoleBasedCondition: CaptureCondition {
    
    /// Roles that are exempt from protection.
    public let exemptRoles: Set<String>
    
    /// Creates a role-based condition.
    ///
    /// - Parameter exemptRoles: User roles that should not trigger protection.
    public init(exemptRoles: Set<String>) {
        self.exemptRoles = exemptRoles
    }
    
    public func shouldProtect(context: CaptureContext) -> Bool {
        guard context.isScreenCaptured || context.isScreenshotEvent else {
            return false
        }
        
        if let role = context.userRole, exemptRoles.contains(role) {
            return false
        }
        
        return true
    }
}

/// Protects only specific screens identified by their screen identifier.
public struct ScreenBasedCondition: CaptureCondition {
    
    /// Screen identifiers that should be protected.
    public let protectedScreens: Set<String>
    
    /// Creates a screen-based condition.
    ///
    /// - Parameter protectedScreens: Screen identifiers that should trigger protection.
    public init(protectedScreens: Set<String>) {
        self.protectedScreens = protectedScreens
    }
    
    public func shouldProtect(context: CaptureContext) -> Bool {
        guard context.isScreenCaptured || context.isScreenshotEvent else {
            return false
        }
        
        guard let screenId = context.screenIdentifier else {
            return false // Unknown screens are not protected
        }
        
        return protectedScreens.contains(screenId)
    }
}

/// Combines multiple conditions with AND logic.
public struct CompositeAndCondition: CaptureCondition {
    
    private let conditions: [any CaptureCondition]
    
    /// Creates a composite condition that requires all conditions to be true.
    ///
    /// - Parameter conditions: The conditions to combine.
    public init(_ conditions: [any CaptureCondition]) {
        self.conditions = conditions
    }
    
    public func shouldProtect(context: CaptureContext) -> Bool {
        return conditions.allSatisfy { $0.shouldProtect(context: context) }
    }
}

/// Combines multiple conditions with OR logic.
public struct CompositeOrCondition: CaptureCondition {
    
    private let conditions: [any CaptureCondition]
    
    /// Creates a composite condition that requires any condition to be true.
    ///
    /// - Parameter conditions: The conditions to combine.
    public init(_ conditions: [any CaptureCondition]) {
        self.conditions = conditions
    }
    
    public func shouldProtect(context: CaptureContext) -> Bool {
        return conditions.contains { $0.shouldProtect(context: context) }
    }
}

// MARK: - Type-Erased Wrapper

/// A type-erased wrapper for `CaptureCondition`.
///
/// Use this when you need to store conditions with different concrete types.
public struct AnyCaptureCondition: CaptureCondition {
    
    private let _shouldProtect: @Sendable (CaptureContext) -> Bool
    
    /// Creates a type-erased condition.
    ///
    /// - Parameter condition: The condition to wrap.
    public init(_ condition: some CaptureCondition) {
        self._shouldProtect = condition.shouldProtect
    }
    
    /// Creates a condition from a closure.
    ///
    /// - Parameter shouldProtect: A closure that evaluates the condition.
    public init(_ shouldProtect: @escaping @Sendable (CaptureContext) -> Bool) {
        self._shouldProtect = shouldProtect
    }
    
    public func shouldProtect(context: CaptureContext) -> Bool {
        return _shouldProtect(context)
    }
}
