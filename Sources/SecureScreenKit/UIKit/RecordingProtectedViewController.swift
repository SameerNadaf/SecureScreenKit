//
//  RecordingProtectedViewController.swift
//  SecureScreenKit
//
//  UIViewController with recording protection overlay
//

import UIKit
import Combine

/// A UIViewController subclass with integrated recording protection.
///
/// `RecordingProtectedViewController` provides built-in protection for its content,
/// automatically showing an overlay when screen recording is detected.
///
/// ## Usage
///
/// ### Subclassing
/// ```swift
/// class BankingViewController: RecordingProtectedViewController {
///     override func viewDidLoad() {
///         super.viewDidLoad()
///         policy = .block(reason: "Banking data protected")
///         // Add your UI setup
///     }
/// }
/// ```
///
/// ### Direct Use with Extension
/// ```swift
/// let viewController = UIViewController()
/// viewController.protectFromRecording(policy: .obscure(style: .blur(radius: 20)))
/// ```
@MainActor
open class RecordingProtectedViewController: UIViewController {
    
    // MARK: - Properties
    
    /// The protection policy for this controller.
    open var policy: CapturePolicy = SecureScreenConfiguration.shared.defaultPolicy {
        didSet {
            updateProtection()
        }
    }
    
    /// Optional condition for conditional protection.
    open var condition: (any CaptureCondition)? {
        didSet {
            updateProtection()
        }
    }
    
    /// Screen identifier for context.
    open var screenIdentifier: String?
    
    /// User role for context.
    open var userRole: String?
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private var overlayView: UIView?
    private let monitor = CaptureMonitor.shared
    private let policyEngine = CapturePolicyEngine.shared
    
    // MARK: - Lifecycle
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupCaptureMonitoring()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateProtection()
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        removeOverlay()
    }
    
    // MARK: - Setup
    
    private func setupCaptureMonitoring() {
        monitor.$captureState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateProtection()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Protection
    
    private func updateProtection() {
        let action = policyEngine.resolvePolicy(
            policy,
            condition: condition,
            screenIdentifier: screenIdentifier,
            userRole: userRole
        )
        
        if action.requiresAction {
            showOverlay(for: action)
        } else {
            removeOverlay()
        }
    }
    
    private func showOverlay(for action: ResolvedAction) {
        // Remove existing overlay
        removeOverlay()
        
        let overlay: UIView
        
        switch action {
        case .none:
            return
            
        case .obscure(let style):
            overlay = createObscureOverlay(style: style)
            
        case .block(let reason):
            overlay = createBlockingOverlay(reason: reason)
            
        case .logout:
            overlay = createBlockingOverlay(reason: "Session ended for security")
        }
        
        overlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlay)
        
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Show immediately (no animation for security)
        self.overlayView = overlay
    }
    
    private func removeOverlay() {
        guard let overlay = overlayView else { return }
        
        // Remove immediately (no animation for security)
        overlay.removeFromSuperview()
        overlayView = nil
    }
    
    private func createObscureOverlay(style: ObscureStyle) -> UIView {
        switch style {
        case .blur(let radius):
            let blurStyle: UIBlurEffect.Style = radius < 15 ? .systemThinMaterial : .systemThickMaterial
            let blurEffect = UIBlurEffect(style: blurStyle)
            let blurView = UIVisualEffectView(effect: blurEffect)
            return blurView
            
        case .blackout:
            let view = UIView()
            view.backgroundColor = .black
            return view
            
        case .custom(let viewProvider):
            return viewProvider()
        }
    }
    
    private func createBlockingOverlay(reason: String?) -> UIView {
        let container = UIView()
        container.backgroundColor = .black
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 48, weight: .medium)
        let icon = UIImageView(image: UIImage(systemName: "lock.shield.fill", withConfiguration: iconConfig))
        icon.tintColor = .white
        
        let titleLabel = UILabel()
        titleLabel.text = "Content Protected"
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = .white
        
        stack.addArrangedSubview(icon)
        stack.addArrangedSubview(titleLabel)
        
        if let reason = reason {
            let messageLabel = UILabel()
            messageLabel.text = reason
            messageLabel.font = .systemFont(ofSize: 14)
            messageLabel.textColor = UIColor.white.withAlphaComponent(0.8)
            messageLabel.textAlignment = .center
            messageLabel.numberOfLines = 0
            stack.addArrangedSubview(messageLabel)
        }
        
        container.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -32)
        ])
        
        return container
    }
    
    // MARK: - Public Methods
    
    /// Configures protection with the specified policy and condition.
    ///
    /// - Parameters:
    ///   - policy: The protection policy to apply.
    ///   - condition: Optional condition for conditional protection.
    public func configureProtection(
        policy: CapturePolicy,
        condition: (any CaptureCondition)? = nil
    ) {
        self.policy = policy
        self.condition = condition
    }
}

// MARK: - Deprecated Alias for Backward Compatibility

@available(*, deprecated, renamed: "RecordingProtectedViewController")
public typealias SecureViewController = RecordingProtectedViewController
