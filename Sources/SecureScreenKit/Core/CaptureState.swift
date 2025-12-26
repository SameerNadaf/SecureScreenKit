//
//  CaptureState.swift
//  SecureScreenKit
//
//  Enterprise-grade screen capture protection for iOS
//

import Foundation

/// Represents the current screen capture state.
///
/// This enum tracks whether the device is currently being screen recorded,
/// a screenshot was recently taken, or no capture activity is occurring.
///
/// - Note: iOS does not allow blocking captures—only detection and response.
public enum CaptureState: Equatable, Sendable {
    
    /// No screen capture activity is occurring.
    case idle
    
    /// Screen recording is currently active.
    ///
    /// This is detected via `UIScreen.main.isCaptured` and includes:
    /// - iOS screen recording
    /// - AirPlay mirroring
    /// - QuickTime recording via cable
    /// - Third-party screen mirroring apps
    case recording
    
    /// A screenshot was just taken.
    ///
    /// This state is transient and is triggered by
    /// `UIApplication.userDidTakeScreenshotNotification`.
    ///
    /// - Important: The screenshot has already been captured when this fires.
    ///   We cannot prevent it, only respond to it.
    case screenshotTaken
    
    /// Whether any form of capture is currently active or recently occurred.
    public var isCaptureActive: Bool {
        switch self {
        case .idle:
            return false
        case .recording, .screenshotTaken:
            return true
        }
    }
    
    /// Whether screen recording is specifically active.
    public var isRecording: Bool {
        self == .recording
    }
}
