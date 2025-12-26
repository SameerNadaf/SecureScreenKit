//
//  ScreenProtectedView.swift
//  SecureScreenKit
//
//  Complete protection: hides content from BOTH screenshots AND recordings
//

import SwiftUI
import Combine

/// A SwiftUI view that provides COMPLETE protection for its content.
///
/// `ScreenProtectedView` combines two protection techniques:
/// 1. **Screenshot Protection**: Uses `isSecureTextEntry` trick to make content invisible in screenshots
/// 2. **Recording Protection**: Shows overlay during screen recording
///
/// ## Example Usage
/// ```swift
/// ScreenProtectedView {
///     SensitiveDataView()
/// }
/// ```
///
/// - Important: Content inside this view will be hidden from BOTH screenshots AND screen recordings.

public struct ScreenProtectedView<Content: View>: View {
    
    private let content: Content
    private let policy: CapturePolicy
    
    @ObservedObject private var viewModel: ScreenProtectedViewModel
    
    /// Creates a screen-protected view with default blur overlay for recording protection.
    ///
    /// - Parameter content: The content to protect.
    @MainActor
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
        self.policy = .obscure(style: .blur(radius: 25))
        self.viewModel = ScreenProtectedViewModel()
    }
    
    /// Creates a screen-protected view with a custom policy for recording protection.
    ///
    /// - Parameters:
    ///   - recordingPolicy: The policy to apply during screen recording.
    ///   - content: The content to protect.
    @MainActor
    public init(recordingPolicy: CapturePolicy, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.policy = recordingPolicy
        self.viewModel = ScreenProtectedViewModel()
    }
    
    public var body: some View {
        // Layer 1: Screenshot protection (isSecureTextEntry trick)
        ScreenshotProofView {
            // Layer 2: Recording protection (overlay)
            content
                .overlay(
                    Group {
                        if viewModel.isRecording {
                            recordingOverlay
                        }
                    }
                )
        }
        .onAppear {
            viewModel.startMonitoring()
        }
        .onDisappear {
            viewModel.stopMonitoring()
        }
    }
    
    @ViewBuilder
    private var recordingOverlay: some View {
        switch policy {
        case .allow:
            EmptyView()
            
        case .obscure(let style):
            obscureView(for: style)
            
        case .block(let reason):
            BlockingOverlayView(reason: reason)
            
        case .logout:
            BlockingOverlayView(reason: "Session ended for security")
        }
    }
    
    @ViewBuilder
    private func obscureView(for style: ObscureStyle) -> some View {
        switch style {
        case .blur(let radius):
            BlurOverlayView(radius: radius)
            
        case .blackout:
            Color.black
            
        case .custom(let viewProvider):
            CustomOverlayView(viewProvider: viewProvider)
        }
    }
}

// MARK: - ViewModel


@MainActor
internal final class ScreenProtectedViewModel: ObservableObject {
    
    @Published private(set) var isRecording: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private let monitor = CaptureMonitor.shared
    
    func startMonitoring() {
        monitor.$isRecording
            .receive(on: DispatchQueue.main)
            .assign(to: &$isRecording)
    }
    
    func stopMonitoring() {
        cancellables.removeAll()
    }
}

// MARK: - View Extension


public extension View {
    
    /// Makes this view completely protected from both screenshots and screen recordings.
    ///
    /// This modifier combines:
    /// 1. Screenshot protection (content invisible in screenshots)
    /// 2. Recording protection (blur overlay during recording)
    ///
    /// ## Example
    /// ```swift
    /// Text("Secret PIN: 1234")
    ///     .screenProtected()
    /// ```
    ///
    /// - Returns: A view that is hidden from both screenshots and recordings.
    func screenProtected() -> some View {
        ScreenProtectedView {
            self
        }
    }
    
    /// Makes this view completely protected with a custom recording protection policy.
    ///
    /// - Parameter recordingPolicy: The policy to apply during screen recording.
    /// - Returns: A view that is hidden from both screenshots and recordings.
    func screenProtected(recordingPolicy: CapturePolicy) -> some View {
        ScreenProtectedView(recordingPolicy: recordingPolicy) {
            self
        }
    }
}

// MARK: - Deprecated Aliases for Backward Compatibility


@available(*, deprecated, renamed: "ScreenProtectedView")
public typealias SecureView = ScreenProtectedView


public extension View {
    @available(*, deprecated, renamed: "screenProtected")
    func secure() -> some View {
        screenProtected()
    }
    
    @available(*, deprecated, renamed: "screenProtected(recordingPolicy:)")
    func secure(recordingPolicy: CapturePolicy) -> some View {
        screenProtected(recordingPolicy: recordingPolicy)
    }
}
