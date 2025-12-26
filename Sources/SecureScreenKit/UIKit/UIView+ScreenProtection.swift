//
//  UIView+ScreenProtection.swift
//  SecureScreenKit
//
//  Extensions for screen protection on UIView and UIViewController
//

import UIKit
import Combine

/// Extension providing screen capture protection for UIView.
///
/// This extension adds the ability to protect individual views from
/// screen capture using both the secure text container technique
/// and overlay-based protection.
public extension UIView {
    
    // MARK: - Associated Keys
    
    private enum AssociatedKeys {
        static var secureContainer = "secureContainer"
        static var overlayView = "overlayView"
        static var cancellables = "cancellables"
        static var policy = "policy"
    }
    
    // MARK: - Properties
    
    /// The secure container wrapping this view (if any).
    private var secureContainer: UIView? {
        get {
            objc_getAssociatedObject(self, &AssociatedKeys.secureContainer) as? UIView
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.secureContainer, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// The protection overlay on this view (if any).
    private var protectionOverlay: UIView? {
        get {
            objc_getAssociatedObject(self, &AssociatedKeys.overlayView) as? UIView
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.overlayView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// Cancellables for Combine subscriptions.
    private var screenProtectionCancellables: Set<AnyCancellable> {
        get {
            objc_getAssociatedObject(self, &AssociatedKeys.cancellables) as? Set<AnyCancellable> ?? Set<AnyCancellable>()
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.cancellables, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// The current protection policy for this view.
    private(set) var recordingProtectionPolicy: CapturePolicy? {
        get {
            objc_getAssociatedObject(self, &AssociatedKeys.policy) as? CapturePolicy
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.policy, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // MARK: - Screenshot Protection (Secure Text Container)
    
    /// Wraps this view in a screenshot-proof container.
    ///
    /// This technique uses `UITextField.isSecureTextEntry` which causes iOS
    /// to exclude the content from screen captures. This is the most reliable
    /// method for hiding content but has some UI limitations.
    ///
    /// ## Limitations
    /// - The view must be added as a subview of the secure container's layer
    /// - Some animation and layout behaviors may differ
    /// - Best for static content that doesn't need interaction
    ///
    /// - Returns: The secure container view that now hosts this view.
    @discardableResult
    func wrapInScreenshotProofContainer() -> UIView {
        // Remove any existing container
        removeFromScreenshotProofContainer()
        
        // Create the secure text field (hidden but functional)
        let secureTextField = UITextField()
        secureTextField.isSecureTextEntry = true
        secureTextField.isUserInteractionEnabled = false
        secureTextField.translatesAutoresizingMaskIntoConstraints = false
        
        // Get the secure layer from the text field
        guard let secureLayer = secureTextField.layer.sublayers?.first else {
            // Fallback: just return the view's existing superview or self
            return superview ?? self
        }
        
        // Create container
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        // Store original position
        let originalSuperview = superview
        let originalFrame = frame
        let originalConstraints = constraints
        
        // Move this view into secure layer
        removeFromSuperview()
        secureLayer.addSublayer(layer)
        
        // Add text field to container
        container.addSubview(secureTextField)
        
        // Add container to original superview
        if let superview = originalSuperview {
            container.frame = originalFrame
            superview.addSubview(container)
            
            // Restore constraints on container if possible
            for constraint in originalConstraints {
                if constraint.firstItem as? UIView === self {
                    let newConstraint = NSLayoutConstraint(
                        item: container,
                        attribute: constraint.firstAttribute,
                        relatedBy: constraint.relation,
                        toItem: constraint.secondItem,
                        attribute: constraint.secondAttribute,
                        multiplier: constraint.multiplier,
                        constant: constraint.constant
                    )
                    newConstraint.isActive = true
                }
            }
        }
        
        // Store reference
        self.secureContainer = container
        
        return container
    }
    
    /// Removes this view from its screenshot-proof container.
    func removeFromScreenshotProofContainer() {
        guard let container = secureContainer else { return }
        
        // Restore this view's layer to a normal view
        if let superview = container.superview {
            translatesAutoresizingMaskIntoConstraints = false
            superview.insertSubview(self, aboveSubview: container)
            frame = container.frame
        }
        
        container.removeFromSuperview()
        self.secureContainer = nil
    }
    
    // MARK: - Recording Overlay Protection
    
    /// Enables recording protection on this view with the specified policy.
    ///
    /// When screen recording is detected, an overlay matching the policy
    /// will be shown over this view.
    ///
    /// - Parameters:
    ///   - policy: The protection policy to apply.
    ///   - condition: Optional condition for conditional protection.
    func enableRecordingProtection(
        policy: CapturePolicy,
        condition: (any CaptureCondition)? = nil
    ) {
        // Store policy
        recordingProtectionPolicy = policy
        
        // Cancel any existing subscriptions
        screenProtectionCancellables.removeAll()
        
        // Subscribe to capture state changes
        var cancellables = self.screenProtectionCancellables
        
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            CaptureMonitor.shared.$captureState
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.updateRecordingOverlay(policy: policy, condition: condition)
                }
                .store(in: &cancellables)
            
            self.screenProtectionCancellables = cancellables
            
            // Initial check
            self.updateRecordingOverlay(policy: policy, condition: condition)
        }
    }
    
    /// Disables recording protection on this view.
    func disableRecordingProtection() {
        screenProtectionCancellables.removeAll()
        recordingProtectionPolicy = nil
        removeRecordingOverlay()
    }
    
    // MARK: - Private Methods
    
    private func updateRecordingOverlay(
        policy: CapturePolicy,
        condition: (any CaptureCondition)?
    ) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            let engine = CapturePolicyEngine.shared
            let action = engine.resolvePolicy(policy, condition: condition)
            
            if action.requiresAction {
                self.showRecordingOverlay(for: action)
            } else {
                self.removeRecordingOverlay()
            }
        }
    }
    
    private func showRecordingOverlay(for action: ResolvedAction) {
        // Remove existing overlay
        removeRecordingOverlay()
        
        let overlay: UIView
        
        switch action {
        case .none:
            return
            
        case .obscure(let style):
            overlay = createObscureOverlayForView(style: style)
            
        case .block(let reason):
            overlay = createBlockingOverlayForView(reason: reason)
            
        case .logout:
            overlay = createBlockingOverlayForView(reason: "Session ended")
        }
        
        overlay.translatesAutoresizingMaskIntoConstraints = false
        addSubview(overlay)
        
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: topAnchor),
            overlay.leadingAnchor.constraint(equalTo: leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        self.protectionOverlay = overlay
    }
    
    private func removeRecordingOverlay() {
        protectionOverlay?.removeFromSuperview()
        protectionOverlay = nil
    }
    
    private func createObscureOverlayForView(style: ObscureStyle) -> UIView {
        switch style {
        case .blur(let radius):
            let blurStyle: UIBlurEffect.Style = radius < 15 ? .systemThinMaterial : .systemThickMaterial
            let blurEffect = UIBlurEffect(style: blurStyle)
            return UIVisualEffectView(effect: blurEffect)
            
        case .blackout:
            let view = UIView()
            view.backgroundColor = .black
            return view
            
        case .custom(let viewProvider):
            return viewProvider()
        }
    }
    
    private func createBlockingOverlayForView(reason: String?) -> UIView {
        let container = UIView()
        container.backgroundColor = .black.withAlphaComponent(0.9)
        
        let label = UILabel()
        label.text = reason ?? "Protected"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        return container
    }
}

// MARK: - UIViewController Extension

public extension UIViewController {
    
    /// Configures recording protection for this view controller.
    ///
    /// This method adds capture monitoring and will show an overlay
    /// when screen recording is detected, based on the specified policy.
    ///
    /// - Parameters:
    ///   - policy: The protection policy to apply.
    ///   - condition: Optional condition for conditional protection.
    func protectFromRecording(
        policy: CapturePolicy,
        condition: (any CaptureCondition)? = nil
    ) {
        view.enableRecordingProtection(policy: policy, condition: condition)
    }
    
    /// Removes recording protection from this view controller.
    func removeRecordingProtection() {
        view.disableRecordingProtection()
    }
}

// MARK: - Deprecated Aliases for Backward Compatibility

public extension UIView {
    @available(*, deprecated, renamed: "enableRecordingProtection(policy:condition:)")
    func enableCaptureProtection(
        policy: CapturePolicy,
        condition: (any CaptureCondition)? = nil
    ) {
        enableRecordingProtection(policy: policy, condition: condition)
    }
    
    @available(*, deprecated, renamed: "disableRecordingProtection()")
    func disableCaptureProtection() {
        disableRecordingProtection()
    }
    
    @available(*, deprecated, renamed: "wrapInScreenshotProofContainer()")
    @discardableResult
    func wrapInSecureContainer() -> UIView {
        wrapInScreenshotProofContainer()
    }
    
    @available(*, deprecated, renamed: "removeFromScreenshotProofContainer()")
    func removeFromSecureContainer() {
        removeFromScreenshotProofContainer()
    }
    
    @available(*, deprecated, renamed: "recordingProtectionPolicy")
    var securePolicy: CapturePolicy? {
        recordingProtectionPolicy
    }
}

public extension UIViewController {
    @available(*, deprecated, renamed: "protectFromRecording(policy:condition:)")
    func secure(
        policy: CapturePolicy,
        condition: (any CaptureCondition)? = nil
    ) {
        protectFromRecording(policy: policy, condition: condition)
    }
    
    @available(*, deprecated, renamed: "removeRecordingProtection()")
    func removeSecure() {
        removeRecordingProtection()
    }
}
