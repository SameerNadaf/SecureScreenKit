//
//  RecordingOverlayContainer.swift
//  SecureScreenKit
//
//  Container that shows overlay during screen recording
//

import SwiftUI
import Combine

/// A SwiftUI container that protects its content from screen recording with an overlay.
///
/// `RecordingOverlayContainer` wraps your sensitive content and applies a visual overlay
/// (blur, blackout, or blocking message) when screen recording is detected.
///
/// ## Example Usage
///
/// ### Basic Protection
/// ```swift
/// RecordingOverlayContainer {
///     SensitiveDataView()
/// }
/// ```
///
/// ### Custom Policy
/// ```swift
/// RecordingOverlayContainer(policy: .obscure(style: .blur(radius: 25))) {
///     BankAccountView()
/// }
/// ```
///
/// ### Conditional Protection
/// ```swift
/// RecordingOverlayContainer(
///     policy: .block(reason: "Recording not allowed"),
///     condition: RecordingOnlyCondition()
/// ) {
///     MedicalRecordsView()
/// }
/// ```
///
/// - Note: This provides **overlay-based** protection during recording only.
///   For screenshot protection, use `ScreenshotProofView`.
///   For complete protection (both), use `ScreenProtectedView`.
public struct RecordingOverlayContainer<Content: View>: View {
    
    // MARK: - Properties
    
    /// The policy to apply when capture is detected.
    private let policy: CapturePolicy
    
    /// Optional condition for conditional protection.
    private let condition: (any CaptureCondition)?
    
    /// Optional screen identifier for context.
    private let screenIdentifier: String?
    
    /// Optional user role for context.
    private let userRole: String?
    
    /// The content to protect.
    private let content: Content
    
    /// View model for observing capture state.
    @ObservedObject private var viewModel: RecordingOverlayViewModel
    
    // MARK: - Initialization
    
    /// Creates a recording overlay container with default policy from configuration.
    ///
    /// - Parameter content: The content to protect.
    @MainActor
    public init(
        @ViewBuilder content: () -> Content
    ) {
        self.policy = SecureScreenConfiguration.shared.defaultPolicy
        self.condition = nil
        self.screenIdentifier = nil
        self.userRole = nil
        self.content = content()
        self.viewModel = RecordingOverlayViewModel()
    }
    
    /// Creates a recording overlay container with a specified policy.
    ///
    /// - Parameters:
    ///   - policy: The protection policy to apply.
    ///   - content: The content to protect.
    @MainActor
    public init(
        policy: CapturePolicy,
        @ViewBuilder content: () -> Content
    ) {
        self.policy = policy
        self.condition = nil
        self.screenIdentifier = nil
        self.userRole = nil
        self.content = content()
        self.viewModel = RecordingOverlayViewModel()
    }
    
    /// Creates a recording overlay container with policy and condition.
    ///
    /// - Parameters:
    ///   - policy: The protection policy to apply.
    ///   - condition: The condition for when to apply protection.
    ///   - content: The content to protect.
    @MainActor
    public init(
        policy: CapturePolicy,
        condition: (any CaptureCondition)?,
        @ViewBuilder content: () -> Content
    ) {
        self.policy = policy
        self.condition = condition
        self.screenIdentifier = nil
        self.userRole = nil
        self.content = content()
        self.viewModel = RecordingOverlayViewModel()
    }
    
    /// Creates a recording overlay container with full configuration.
    ///
    /// - Parameters:
    ///   - policy: The protection policy to apply.
    ///   - condition: The condition for when to apply protection.
    ///   - screenIdentifier: Identifier for this screen in policy context.
    ///   - userRole: User role for role-based policies.
    ///   - content: The content to protect.
    @MainActor
    public init(
        policy: CapturePolicy,
        condition: (any CaptureCondition)?,
        screenIdentifier: String?,
        userRole: String?,
        @ViewBuilder content: () -> Content
    ) {
        self.policy = policy
        self.condition = condition
        self.screenIdentifier = screenIdentifier
        self.userRole = userRole
        self.content = content()
        self.viewModel = RecordingOverlayViewModel()
    }
    
    // MARK: - Body
    
    public var body: some View {
        content
            .overlay(
                Group {
                    if viewModel.shouldShowProtection(
                        policy: policy,
                        condition: condition,
                        screenIdentifier: screenIdentifier,
                        userRole: userRole
                    ) {
                        protectionOverlay
                    }
                }
            )
            .onAppear {
                viewModel.startMonitoring()
            }
            .onDisappear {
                viewModel.stopMonitoring()
            }
    }
    
    // MARK: - Protection Overlay
    
    @ViewBuilder
    private var protectionOverlay: some View {
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

// MARK: - RecordingOverlayViewModel

@MainActor
internal final class RecordingOverlayViewModel: ObservableObject {
    
    @Published private(set) var captureState: CaptureState = .idle
    
    private var cancellables = Set<AnyCancellable>()
    private let monitor = CaptureMonitor.shared
    private let policyEngine = CapturePolicyEngine.shared
    
    func startMonitoring() {
        monitor.$captureState
            .receive(on: DispatchQueue.main)
            .assign(to: &$captureState)
    }
    
    func stopMonitoring() {
        cancellables.removeAll()
    }
    
    func shouldShowProtection(
        policy: CapturePolicy,
        condition: (any CaptureCondition)?,
        screenIdentifier: String?,
        userRole: String?
    ) -> Bool {
        let action = policyEngine.resolvePolicy(
            policy,
            condition: condition,
            screenIdentifier: screenIdentifier,
            userRole: userRole
        )
        return action.requiresAction
    }
}

// MARK: - Supporting Views

/// Blur overlay for obscure style.
internal struct BlurOverlayView: View {
    let radius: CGFloat
    
    var body: some View {
        #if os(iOS)
        VisualEffectBlur(blurRadius: radius)
        #endif
    }
}

/// Visual effect view wrapper for SwiftUI.
internal struct VisualEffectBlur: UIViewRepresentable {
    let blurRadius: CGFloat
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let style: UIBlurEffect.Style = blurRadius < 15 ? .systemThinMaterial : .systemThickMaterial
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        let style: UIBlurEffect.Style = blurRadius < 15 ? .systemThinMaterial : .systemThickMaterial
        uiView.effect = UIBlurEffect(style: style)
    }
}

/// Blocking overlay with message.
internal struct BlockingOverlayView: View {
    let reason: String?
    
    var body: some View {
        ZStack {
            Color.black
            
            VStack(spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                
                Text("Content Protected")
                    .font(.headline)
                    .foregroundColor(.white)
                
                if let reason = reason {
                    Text(reason)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
            }
            .padding()
        }
    }
}

/// Custom view overlay wrapper.
internal struct CustomOverlayView: UIViewRepresentable {
    let viewProvider: @Sendable () -> UIView
    
    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear
        
        let customView = viewProvider()
        customView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(customView)
        
        NSLayoutConstraint.activate([
            customView.topAnchor.constraint(equalTo: container.topAnchor),
            customView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            customView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            customView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // No updates needed
    }
}

// MARK: - Deprecated Alias for Backward Compatibility

@available(*, deprecated, renamed: "RecordingOverlayContainer")
public typealias SecureContainer = RecordingOverlayContainer
