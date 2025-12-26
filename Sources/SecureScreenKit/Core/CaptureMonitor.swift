//
//  CaptureMonitor.swift
//  SecureScreenKit
//
//  Enterprise-grade screen capture protection for iOS
//

import UIKit
import Combine

/// Central monitor for screen capture detection.
///
/// `CaptureMonitor` observes system notifications for screen recording and
/// screenshot events, publishing state changes that other components can react to.
///
/// ## Detection Methods
/// - **Screen Recording**: Uses `UIScreen.main.isCaptured` and
///   `UIScreen.capturedDidChangeNotification`
/// - **Screenshots**: Uses `UIApplication.userDidTakeScreenshotNotification`
///
/// ## Thread Safety
/// All state changes are dispatched on the main thread using `@MainActor`.
///
/// - Important: This monitor only detects capture events. It cannot prevent them.
@MainActor
internal final class CaptureMonitor: ObservableObject {
    
    // MARK: - Singleton
    
    /// Shared monitor instance.
    static let shared = CaptureMonitor()
    
    // MARK: - Published State
    
    /// Current capture state.
    @Published private(set) var captureState: CaptureState = .idle
    
    /// Whether screen recording is currently active.
    @Published private(set) var isRecording: Bool = false
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private var screenshotResetTask: Task<Void, Never>?
    
    /// Duration to maintain `.screenshotTaken` state before returning to idle.
    private let screenshotStateDuration: TimeInterval = 0.5
    
    // MARK: - Initialization
    
    private init() {
        setupObservers()
        checkInitialState()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Screen recording/mirroring detection
        NotificationCenter.default.publisher(
            for: UIScreen.capturedDidChangeNotification
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.handleCaptureStateChange()
        }
        .store(in: &cancellables)
        
        // Screenshot detection
        NotificationCenter.default.publisher(
            for: UIApplication.userDidTakeScreenshotNotification
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.handleScreenshotTaken()
        }
        .store(in: &cancellables)
        
        // App lifecycle - re-evaluate on becoming active
        NotificationCenter.default.publisher(
            for: UIApplication.didBecomeActiveNotification
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.handleCaptureStateChange()
        }
        .store(in: &cancellables)
        
        // Scene activation (iOS 13+)
        NotificationCenter.default.publisher(
            for: UIScene.didActivateNotification
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.handleCaptureStateChange()
        }
        .store(in: &cancellables)
    }
    
    /// Check if capture is already active at launch.
    private func checkInitialState() {
        handleCaptureStateChange()
    }
    
    // MARK: - State Handlers
    
    private func handleCaptureStateChange() {
        let isCaptured = UIScreen.main.isCaptured
        isRecording = isCaptured
        
        // Don't override screenshot state if it's active
        if captureState == .screenshotTaken {
            return
        }
        
        let newState: CaptureState = isCaptured ? .recording : .idle
        
        if captureState != newState {
            captureState = newState
            notifyViolationHandler(for: newState)
        }
    }
    
    private func handleScreenshotTaken() {
        // Cancel any pending reset
        screenshotResetTask?.cancel()
        
        // Update state
        captureState = .screenshotTaken
        
        // Notify violation handler
        SecureScreenConfiguration.shared.violationHandler?.screenshotTaken()
        
        // Reset to previous state after duration
        screenshotResetTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(500_000_000)) // 0.5 seconds
            
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                self?.resetFromScreenshotState()
            }
        }
    }
    
    private func resetFromScreenshotState() {
        // Return to appropriate state based on current capture status
        let isCaptured = UIScreen.main.isCaptured
        captureState = isCaptured ? .recording : .idle
    }
    
    private func notifyViolationHandler(for state: CaptureState) {
        let handler = SecureScreenConfiguration.shared.violationHandler
        
        switch state {
        case .recording:
            handler?.didStartScreenCapture()
        case .idle:
            handler?.didStopScreenCapture()
        case .screenshotTaken:
            // Handled separately in handleScreenshotTaken
            break
        }
    }
    
    // MARK: - Public Methods
    
    /// Force a re-evaluation of the current capture state.
    ///
    /// Call this when external conditions may have changed, such as
    /// after changing connected displays.
    func refreshState() {
        handleCaptureStateChange()
    }
    
    /// Creates a context for the current capture state.
    ///
    /// - Parameters:
    ///   - screenIdentifier: Optional identifier for the current screen.
    ///   - userRole: Optional role for the current user.
    /// - Returns: A `CaptureContext` reflecting current state.
    func createContext(
        screenIdentifier: String? = nil,
        userRole: String? = nil
    ) -> CaptureContext {
        return CaptureContext(
            isScreenCaptured: isRecording,
            isScreenshotEvent: captureState == .screenshotTaken,
            appState: UIApplication.shared.applicationState,
            screenIdentifier: screenIdentifier,
            userRole: userRole
        )
    }
}
