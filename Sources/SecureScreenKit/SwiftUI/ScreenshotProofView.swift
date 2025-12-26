//
//  ScreenshotProofView.swift
//  SecureScreenKit
//
//  Uses UITextField.isSecureTextEntry trick to hide content from screenshots
//

import SwiftUI
import UIKit

/// A SwiftUI view that hides its content from screenshots and screen recordings.
///
/// This view uses the `UITextField.isSecureTextEntry` technique to make content
/// invisible in screen captures. The content **actually becomes invisible** in the captured image.
///
/// ## How It Works
/// iOS excludes the secure text entry layer from screen captures. By placing
/// content inside this layer, it becomes invisible in screenshots and recordings.
///
/// ## Example Usage
/// ```swift
/// ScreenshotProofView {
///     Text("This text will not appear in screenshots!")
///         .font(.title)
/// }
/// ```
///
/// ## Limitations
/// - Content is ALWAYS hidden from captures (no policy control)
/// - May have slight visual artifacts in some cases
/// - Relies on undocumented iOS behavior (may change in future iOS versions)
///
/// - Important: This is the closest iOS allows to "screenshot-proof" content,
///   but it's not officially supported by Apple for this purpose.
@available(iOS 14.0, *)
public struct ScreenshotProofView<Content: View>: View {
    
    private let content: Content
    
    /// Creates a screenshot-proof view.
    ///
    /// - Parameter content: The content to hide from screenshots.
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
        ScreenshotSecureFieldWrapper {
            content
        }
    }
}

// MARK: - Secure Field Wrapper

/// A UIViewRepresentable that wraps content in a secure text field's layer.
@available(iOS 14.0, *)
internal struct ScreenshotSecureFieldWrapper<Content: View>: UIViewRepresentable {
    
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    func makeUIView(context: Context) -> ScreenshotSecureContainerView {
        let view = ScreenshotSecureContainerView()
        
        // Create hosting controller for SwiftUI content
        let hostingController = UIHostingController(rootView: content)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        // Add the hosting controller's view to the secure layer
        view.addSecureContent(hostingController.view)
        
        // Store for updates
        context.coordinator.hostingController = hostingController
        
        return view
    }
    
    func updateUIView(_ uiView: ScreenshotSecureContainerView, context: Context) {
        context.coordinator.hostingController?.rootView = content
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var hostingController: UIHostingController<Content>?
    }
}

// MARK: - Secure Container View

/// UIView that uses secure text field trick to hide content from screenshots.
@available(iOS 14.0, *)
internal class ScreenshotSecureContainerView: UIView {
    
    private let textField = UITextField()
    private weak var secureLayer: CALayer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSecureTextField()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSecureTextField()
    }
    
    private func setupSecureTextField() {
        // Configure the text field to be secure
        textField.isSecureTextEntry = true
        textField.isUserInteractionEnabled = false
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        // Add to view hierarchy (needed to create secure layer)
        insertSubview(textField, at: 0)
        
        // Text field should be zero-sized and hidden
        NSLayoutConstraint.activate([
            textField.widthAnchor.constraint(equalToConstant: 0),
            textField.heightAnchor.constraint(equalToConstant: 0),
            textField.centerXAnchor.constraint(equalTo: centerXAnchor),
            textField.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        // Trigger layout to create secure layer
        textField.layoutIfNeeded()
        
        // Find the secure layer created by iOS
        findAndStoreSecureLayer()
    }
    
    private func findAndStoreSecureLayer() {
        // The secure layer is typically in the text field's subviews
        if let secureLayer = findSecureLayer(in: textField) {
            self.secureLayer = secureLayer
        }
    }
    
    private func findSecureLayer(in view: UIView) -> CALayer? {
        // First check direct subviews
        for subview in view.subviews {
            // Check if this subview has the characteristic of being the secure container
            if let layer = subview.layer.sublayers?.first {
                return layer
            }
            // Recursively search
            if let found = findSecureLayer(in: subview) {
                return found
            }
        }
        return nil
    }
    
    /// Adds content to be protected from screenshots.
    func addSecureContent(_ contentView: UIView) {
        addSubview(contentView)
        
        // Constrain to fill this view
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Move content view's layer to secure layer if found
        if let secureLayer = secureLayer {
            // Remove from current parent and add to secure layer
            contentView.layer.removeFromSuperlayer()
            secureLayer.addSublayer(contentView.layer)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Ensure secure layer content stays properly sized
        if let secureLayer = secureLayer {
            secureLayer.sublayers?.forEach { sublayer in
                sublayer.frame = bounds
            }
        }
    }
}

// MARK: - Pure UIKit Implementation

/// A UIView that hides its content from screenshots and screen recordings.
///
/// Uses the secure text field technique for UIKit-based content.
///
/// ## Example Usage
/// ```swift
/// let screenshotProofView = ScreenshotProofUIView()
/// screenshotProofView.addSecureSubview(mySecretLabel)
/// view.addSubview(screenshotProofView)
/// ```
@available(iOS 14.0, *)
public class ScreenshotProofUIView: UIView {
    
    private let secureTextField = UITextField()
    private var contentContainer: UIView?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        // Create secure text field
        secureTextField.isSecureTextEntry = true
        secureTextField.isUserInteractionEnabled = false
        secureTextField.translatesAutoresizingMaskIntoConstraints = false
        addSubview(secureTextField)
        
        // Make text field invisible but present
        NSLayoutConstraint.activate([
            secureTextField.widthAnchor.constraint(equalToConstant: 0),
            secureTextField.heightAnchor.constraint(equalToConstant: 0)
        ])
        
        // Trigger secure layer creation
        secureTextField.layoutIfNeeded()
    }
    
    /// Adds a subview that will be hidden from screenshots.
    ///
    /// - Parameter view: The view to protect.
    public func addSecureSubview(_ view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        
        // Find secure layer
        if let secureLayer = findSecureContainer() {
            // Add view normally first
            addSubview(view)
            
            // Move layer to secure container
            view.layer.removeFromSuperlayer()
            secureLayer.addSublayer(view.layer)
            
            contentContainer = view
        } else {
            // Fallback: just add normally
            addSubview(view)
            contentContainer = view
        }
        
        // Keep constraints working
        if let container = contentContainer, container.superview == self {
            NSLayoutConstraint.activate([
                container.topAnchor.constraint(equalTo: topAnchor),
                container.leadingAnchor.constraint(equalTo: leadingAnchor),
                container.trailingAnchor.constraint(equalTo: trailingAnchor),
                container.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        }
    }
    
    private func findSecureContainer() -> CALayer? {
        for subview in secureTextField.subviews {
            if let layer = subview.layer.sublayers?.first {
                return layer
            }
        }
        return secureTextField.layer.sublayers?.first
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update content layer frame
        if let layer = findSecureContainer() {
            layer.sublayers?.forEach { $0.frame = bounds }
        }
    }
}

// MARK: - SwiftUI View Extension

@available(iOS 14.0, *)
public extension View {
    
    /// Makes this view's content invisible in screenshots and screen recordings.
    ///
    /// Uses the secure text field technique to exclude content from captures.
    ///
    /// ## Example
    /// ```swift
    /// Text("Secret PIN: 1234")
    ///     .screenshotProtected()
    /// ```
    ///
    /// - Warning: This relies on undocumented iOS behavior and may not work
    ///   in all scenarios or future iOS versions.
    ///
    /// - Returns: A view that is hidden from screen captures.
    func screenshotProtected() -> some View {
        ScreenshotProofView {
            self
        }
    }
}

// MARK: - Deprecated Aliases for Backward Compatibility

@available(iOS 14.0, *)
@available(*, deprecated, renamed: "ScreenshotProofView")
public typealias SecureContentView = ScreenshotProofView

@available(iOS 14.0, *)
@available(*, deprecated, renamed: "ScreenshotProofUIView")
public typealias SecureUIView = ScreenshotProofUIView

@available(iOS 14.0, *)
public extension View {
    @available(*, deprecated, renamed: "screenshotProtected")
    func screenshotProof() -> some View {
        screenshotProtected()
    }
}
