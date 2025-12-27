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
/// - Relies on undocumented iOS behavior (may change in future iOS versions)
///
/// - Important: This is the closest iOS allows to "screenshot-proof" content,
///   but it's not officially supported by Apple for this purpose.

public struct ScreenshotProofView<Content: View>: View {
    
    private let content: Content
    
    /// Creates a screenshot-proof view.
    ///
    /// - Parameter content: The content to hide from screenshots.
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
        ScreenshotProofRepresentable {
            content
        }
    }
}

// MARK: - Secure Container (UIViewRepresentable)

/// A UIViewRepresentable that wraps content in a secure text field's layer.
internal struct ScreenshotProofRepresentable<Content: View>: UIViewRepresentable {
    
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    func makeUIView(context: Context) -> ScreenshotProofContainerView {
        let containerView = ScreenshotProofContainerView()
        
        // Create hosting controller for SwiftUI content
        let hostingController = UIHostingController(rootView: content)
        hostingController.view.backgroundColor = .clear
        
        // Add to the secure container
        containerView.addSecureContent(hostingController.view)
        
        // Store for updates
        context.coordinator.hostingController = hostingController
        
        return containerView
    }
    
    func updateUIView(_ uiView: ScreenshotProofContainerView, context: Context) {
        context.coordinator.hostingController?.rootView = content
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var hostingController: UIHostingController<Content>?
    }
}

// MARK: - Screenshot Proof Container UIView

/// UIView that uses secure text field trick to hide content from screenshots.
/// The key is that content added as subview of the secure text field's internal
/// container view will be hidden from screenshots.
internal class ScreenshotProofContainerView: UIView {
    
    private let secureTextField = UITextField()
    private weak var secureContainer: UIView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        backgroundColor = .clear
        
        // Configure secure text field
        secureTextField.isSecureTextEntry = true
        secureTextField.isUserInteractionEnabled = false
        secureTextField.backgroundColor = .clear
        secureTextField.translatesAutoresizingMaskIntoConstraints = false
        
        // Add text field to hierarchy
        addSubview(secureTextField)
        
        // Make text field fill the view
        NSLayoutConstraint.activate([
            secureTextField.topAnchor.constraint(equalTo: topAnchor),
            secureTextField.leadingAnchor.constraint(equalTo: leadingAnchor),
            secureTextField.trailingAnchor.constraint(equalTo: trailingAnchor),
            secureTextField.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Force layout to create internal structure
        secureTextField.layoutIfNeeded()
        
        // Find the secure container
        findSecureContainer()
    }
    
    private func findSecureContainer() {
        // iOS creates a special container view inside secure text fields
        if let container = secureTextField.subviews.first {
            self.secureContainer = container
            container.isUserInteractionEnabled = true
        }
    }
    
    /// Adds content to be protected from screenshots.
    func addSecureContent(_ view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        
        // Try to add to secure container if found
        if let container = secureContainer {
            container.addSubview(view)
            
            NSLayoutConstraint.activate([
                view.topAnchor.constraint(equalTo: topAnchor),
                view.leadingAnchor.constraint(equalTo: leadingAnchor),
                view.trailingAnchor.constraint(equalTo: trailingAnchor),
                view.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        } else {
            // Fallback - add directly (won't have screenshot protection)
            addSubview(view)
            
            NSLayoutConstraint.activate([
                view.topAnchor.constraint(equalTo: topAnchor),
                view.leadingAnchor.constraint(equalTo: leadingAnchor),
                view.trailingAnchor.constraint(equalTo: trailingAnchor),
                view.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Ensure secure container fills bounds
        secureContainer?.frame = bounds
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

public class ScreenshotProofUIView: UIView {
    
    private let secureTextField = UITextField()
    private weak var secureContainer: UIView?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        backgroundColor = .clear
        
        // Configure secure text field
        secureTextField.isSecureTextEntry = true
        secureTextField.isUserInteractionEnabled = false
        secureTextField.backgroundColor = .clear
        secureTextField.translatesAutoresizingMaskIntoConstraints = false
        
        // Add to hierarchy
        addSubview(secureTextField)
        
        // Fill entire view
        NSLayoutConstraint.activate([
            secureTextField.topAnchor.constraint(equalTo: topAnchor),
            secureTextField.leadingAnchor.constraint(equalTo: leadingAnchor),
            secureTextField.trailingAnchor.constraint(equalTo: trailingAnchor),
            secureTextField.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Trigger layout
        secureTextField.layoutIfNeeded()
        
        // Find secure container
        if let container = secureTextField.subviews.first {
            secureContainer = container
            container.isUserInteractionEnabled = true
        }
    }
    
    /// Adds a subview that will be hidden from screenshots.
    ///
    /// - Parameter view: The view to protect.
    public func addSecureSubview(_ view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        
        if let container = secureContainer {
            container.addSubview(view)
            
            NSLayoutConstraint.activate([
                view.topAnchor.constraint(equalTo: topAnchor),
                view.leadingAnchor.constraint(equalTo: leadingAnchor),
                view.trailingAnchor.constraint(equalTo: trailingAnchor),
                view.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        } else {
            addSubview(view)
            
            NSLayoutConstraint.activate([
                view.topAnchor.constraint(equalTo: topAnchor),
                view.leadingAnchor.constraint(equalTo: leadingAnchor),
                view.trailingAnchor.constraint(equalTo: trailingAnchor),
                view.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        secureContainer?.frame = bounds
    }
}

// MARK: - SwiftUI View Extension

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

@available(*, deprecated, renamed: "ScreenshotProofView")
public typealias SecureContentView = ScreenshotProofView

@available(*, deprecated, renamed: "ScreenshotProofUIView")
public typealias SecureUIView = ScreenshotProofUIView

public extension View {
    @available(*, deprecated, renamed: "screenshotProtected")
    func screenshotProof() -> some View {
        screenshotProtected()
    }
}
