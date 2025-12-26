//
//  SecureContainerView.swift
//  SecureScreenKit
//
//  UIKit container view that protects its content from screen capture
//

import UIKit
import Combine

/// A UIView container that protects its content from screen capture.
///
/// `SecureContainerView` wraps your sensitive content and applies protection
/// based on the specified policy when screen capture is detected.
///
/// ## Example Usage
///
/// ### Basic Protection
/// ```swift
/// let secureContainer = SecureContainerView()
/// secureContainer.addProtectedSubview(sensitiveView)
/// view.addSubview(secureContainer)
/// ```
///
/// ### Custom Policy
/// ```swift
/// let secureContainer = SecureContainerView(policy: .obscure(style: .blur(radius: 25)))
/// secureContainer.addProtectedSubview(bankAccountView)
/// ```
///
/// ### Conditional Protection
/// ```swift
/// let secureContainer = SecureContainerView(
///     policy: .block(reason: "Recording not allowed"),
///     condition: RecordingOnlyCondition()
/// )
/// secureContainer.addProtectedSubview(medicalRecordsView)
/// ```
@MainActor
public class SecureContainerView: UIView {
    
    // MARK: - Properties
    
    /// The protection policy to apply when capture is detected.
    public var policy: CapturePolicy {
        didSet {
            updateProtection()
        }
    }
    
    /// Optional condition for conditional protection.
    public var condition: (any CaptureCondition)? {
        didSet {
            updateProtection()
        }
    }
    
    /// Screen identifier for context.
    public var screenIdentifier: String? {
        didSet {
            updateProtection()
        }
    }
    
    /// User role for context.
    public var userRole: String? {
        didSet {
            updateProtection()
        }
    }
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let monitor = CaptureMonitor.shared
    private let policyEngine = CapturePolicyEngine.shared
    
    private var contentView: UIView?
    private var overlayView: UIView?
    private var isMonitoring = false
    
    // MARK: - Initialization
    
    /// Creates a secure container with default policy from configuration.
    public convenience init() {
        self.init(policy: SecureScreenConfiguration.shared.defaultPolicy)
    }
    
    /// Creates a secure container with a specified policy.
    ///
    /// - Parameter policy: The protection policy to apply.
    public init(policy: CapturePolicy) {
        self.policy = policy
        super.init(frame: .zero)
        setup()
    }
    
    /// Creates a secure container with policy and condition.
    ///
    /// - Parameters:
    ///   - policy: The protection policy to apply.
    ///   - condition: The condition for when to apply protection.
    public convenience init(policy: CapturePolicy, condition: (any CaptureCondition)?) {
        self.init(policy: policy)
        self.condition = condition
    }
    
    required init?(coder: NSCoder) {
        self.policy = SecureScreenConfiguration.shared.defaultPolicy
        super.init(coder: coder)
        setup()
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Setup
    
    private func setup() {
        backgroundColor = .clear
        clipsToBounds = true
    }
    
    // MARK: - Public Methods
    
    /// Adds a subview that will be protected from screen capture.
    ///
    /// - Parameter view: The view to protect.
    public func addProtectedSubview(_ view: UIView) {
        // Remove existing content
        contentView?.removeFromSuperview()
        
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: topAnchor),
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        contentView = view
        
        // Start monitoring if not already
        startMonitoring()
    }
    
    /// Starts monitoring for screen capture events.
    public func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        monitor.$captureState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateProtection()
            }
            .store(in: &cancellables)
        
        // Check initial state
        updateProtection()
    }
    
    /// Stops monitoring for screen capture events.
    public func stopMonitoring() {
        isMonitoring = false
        cancellables.removeAll()
        removeOverlay()
    }
    
    // MARK: - Protection Logic
    
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
        addSubview(overlay)
        
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: topAnchor),
            overlay.leadingAnchor.constraint(equalTo: leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Show immediately (no animation for security)
        overlay.alpha = 1
        
        self.overlayView = overlay
    }
    
    private func removeOverlay() {
        guard let overlay = overlayView else { return }
        
        // Remove immediately (no animation for security)
        overlay.removeFromSuperview()
        overlayView = nil
    }
    
    // MARK: - Overlay Creation
    
    private func createObscureOverlay(style: ObscureStyle) -> UIView {
        switch style {
        case .blur(let radius):
            let blurStyle: UIBlurEffect.Style
            if radius < 10 {
                blurStyle = .systemThinMaterial
            } else if radius < 25 {
                blurStyle = .systemMaterial
            } else {
                blurStyle = .systemThickMaterial
            }
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
    
    private func createBlockingOverlay(reason: String?) -> UIView {
        let container = UIView()
        container.backgroundColor = .black
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        // Lock icon
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 32, weight: .medium)
        let icon = UIImageView(image: UIImage(systemName: "lock.shield.fill", withConfiguration: iconConfig))
        icon.tintColor = .white
        
        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Content Protected"
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .white
        
        stack.addArrangedSubview(icon)
        stack.addArrangedSubview(titleLabel)
        
        // Reason (if provided)
        if let reason = reason {
            let messageLabel = UILabel()
            messageLabel.text = reason
            messageLabel.font = .systemFont(ofSize: 13)
            messageLabel.textColor = UIColor.white.withAlphaComponent(0.8)
            messageLabel.textAlignment = .center
            messageLabel.numberOfLines = 0
            stack.addArrangedSubview(messageLabel)
        }
        
        container.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -16)
        ])
        
        return container
    }
    
    // MARK: - Lifecycle
    
    public override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        
        if newWindow != nil && contentView != nil {
            startMonitoring()
        }
    }
    
    public override func removeFromSuperview() {
        stopMonitoring()
        super.removeFromSuperview()
    }
}
