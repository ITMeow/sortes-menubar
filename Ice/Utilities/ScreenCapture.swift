//
//  ScreenCapture.swift
//  Ice
//

import CoreGraphics
import ScreenCaptureKit

/// A namespace for screen capture operations.
enum ScreenCapture {
    /// Returns a Boolean value that indicates whether the app has been granted screen capture permissions.
    static func checkPermissions() -> Bool {
        // On macOS 16+, use a combination of methods for more reliable detection
        if #available(macOS 16.0, *) {
            // First, try the legacy method which actually attempts to capture content
            // This is more reliable than API-based checks on macOS 16+
            let legacyResult = checkPermissionsLegacy()
            Logger.screenCapture.debug("Legacy permission check result: \(legacyResult)")

            if legacyResult {
                return true
            }

            // If legacy check fails, also try SCShareableContent as a secondary check
            let modernResult = checkPermissionsModern()
            Logger.screenCapture.debug("Modern permission check result: \(modernResult)")

            return modernResult
        }

        return checkPermissionsLegacy()
    }

    /// Modern permission check for macOS 16+
    /// Note: This may return false even if permission is granted until app restart
    @available(macOS 16.0, *)
    private static func checkPermissionsModern() -> Bool {
        // Try to get shareable content - this will fail if no permission
        var hasPermission = false
        let semaphore = DispatchSemaphore(value: 0)

        SCShareableContent.getWithCompletionHandler { content, error in
            if let error = error as? NSError {
                // SCStreamErrorUserDeclined (-3801) means permission was denied
                // SCStreamErrorNoAccessPermission (-3802) means no permission granted yet
                // Note: -3801 can also appear when permission was granted but app hasn't restarted
                let errorCode = error.code
                Logger.screenCapture.debug("SCShareableContent check - error code: \(errorCode), domain: \(error.domain)")

                // If we get any error, permission is not granted (or not yet detected)
                hasPermission = false
            } else if content != nil {
                // Got content successfully, we have permission
                Logger.screenCapture.debug("SCShareableContent check - got content, permission granted")
                hasPermission = true
            } else {
                // No error but no content - treat as no permission
                Logger.screenCapture.debug("SCShareableContent check - no content and no error, assuming no permission")
                hasPermission = false
            }
            semaphore.signal()
        }

        let waitResult = semaphore.wait(timeout: .now() + 3.0)
        if waitResult == .timedOut {
            Logger.screenCapture.warning("SCShareableContent check timed out after 3 seconds")
            return false
        }

        return hasPermission
    }

    /// Legacy permission check by actually attempting to read window content
    /// This is more reliable as it tests the actual capability
    private static func checkPermissionsLegacy() -> Bool {
        // Try to get menu bar items and check if we can read their titles
        // If we have permission, we can read the title; if not, title will be nil
        for item in MenuBarItem.getMenuBarItems(onScreenOnly: false, activeSpaceOnly: true) {
            // Don't check items owned by Ice.
            if item.owningApplication == .current {
                continue
            }
            // If we can read the title of any non-Ice menu bar item, we have permission
            if item.title != nil {
                Logger.screenCapture.debug("Legacy check: Found readable menu bar item title, permission granted")
                return true
            }
        }

        // As a fallback, try to capture a small screenshot of the menu bar area
        // This tests actual capture capability
        let menuBarRect = CGRect(x: 0, y: 0, width: 100, height: 25)
        if let image = CGWindowListCreateImage(
            menuBarRect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            [.boundsIgnoreFraming]
        ) {
            // Check if the image has actual content (not just a blank/black image)
            // A valid capture should have non-zero dimensions
            if image.width > 0 && image.height > 0 {
                Logger.screenCapture.debug("Legacy check: Successfully captured menu bar image, permission granted")
                return true
            }
        }

        // Final fallback to the preflight API
        // Note: This API may return stale values until app restart
        let preflightResult = CGPreflightScreenCaptureAccess()
        Logger.screenCapture.debug("Legacy check: CGPreflightScreenCaptureAccess returned \(preflightResult)")
        return preflightResult
    }

    /// Returns a Boolean value that indicates whether the app has been granted screen capture permissions.
    ///
    /// The first time this function is called, the permissions state is computed, cached, and returned.
    /// Subsequent calls either return the cached value, or recompute the permissions state before caching
    /// and returning it.
    static func cachedCheckPermissions(reset: Bool = false) -> Bool {
        enum Context {
            static var lastCheckResult: Bool?
        }

        if !reset {
            if let lastCheckResult = Context.lastCheckResult {
                return lastCheckResult
            }
        }

        let realResult = checkPermissions()
        Context.lastCheckResult = realResult
        return realResult
    }

    /// Requests screen capture permissions.
    /// This will trigger the system permission dialog and add the app to the Screen Recording list.
    static func requestPermissions() {
        // Always call CGRequestScreenCaptureAccess() first - this is the only reliable way
        // to add the app to the Screen Recording list in System Settings
        let result = CGRequestScreenCaptureAccess()
        Logger.screenCapture.debug("CGRequestScreenCaptureAccess returned: \(result)")

        // On macOS 15+, also try SCShareableContent as a backup trigger
        if #available(macOS 15.0, *) {
            // SCShareableContent.getWithCompletionHandler may also trigger permission request
            SCShareableContent.getWithCompletionHandler { content, error in
                if let error = error {
                    Logger.screenCapture.debug("SCShareableContent permission request error: \(error.localizedDescription)")
                } else {
                    Logger.screenCapture.debug("SCShareableContent permission request succeeded")
                }
            }
        }
    }

    /// Captures a composite image of an array of windows.
    ///
    /// - Parameters:
    ///   - windowIDs: The identifiers of the windows to capture.
    ///   - screenBounds: The bounds to capture. Pass `nil` to capture the minimum rectangle that encloses the windows.
    ///   - option: Options that specify the image to be captured.
    static func captureWindows(_ windowIDs: [CGWindowID], screenBounds: CGRect? = nil, option: CGWindowImageOption = []) -> CGImage? {
        // On macOS 16+, ScreenCaptureKit fails for offscreen windows (negative X coordinates)
        // These are common for Hidden/AlwaysHidden menu bar sections
        // Always use legacy method which handles offscreen windows correctly
        return captureWindowsLegacy(windowIDs, screenBounds: screenBounds, option: option)
    }

    /// Legacy window capture using CGWindowListCreateImage
    private static func captureWindowsLegacy(_ windowIDs: [CGWindowID], screenBounds: CGRect? = nil, option: CGWindowImageOption = []) -> CGImage? {
        let pointer = UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: windowIDs.count)
        defer { pointer.deallocate() }

        for (index, windowID) in windowIDs.enumerated() {
            pointer[index] = UnsafeRawPointer(bitPattern: UInt(windowID))
        }
        guard let windowArray = CFArrayCreate(kCFAllocatorDefault, pointer, windowIDs.count, nil) else {
            return nil
        }
        return .windowListImage(from: screenBounds ?? .null, windowArray: windowArray, imageOption: option)
    }

    /// Modern window capture using ScreenCaptureKit for macOS 16+
    @available(macOS 16.0, *)
    private static func captureWindowsModern(_ windowIDs: [CGWindowID], screenBounds: CGRect? = nil) -> CGImage? {
        guard !windowIDs.isEmpty else { return nil }

        var resultImage: CGImage?
        let semaphore = DispatchSemaphore(value: 0)

        SCShareableContent.getWithCompletionHandler { content, error in
            guard let content = content, error == nil else {
                Logger.screenCapture.warning("SCShareableContent.get failed: \(error?.localizedDescription ?? "unknown error")")
                semaphore.signal()
                return
            }

            // Find SCWindow objects matching our window IDs
            let windowIDSet = Set(windowIDs)
            let matchingWindows = content.windows.filter { windowIDSet.contains(CGWindowID($0.windowID)) }

            Logger.screenCapture.debug("Looking for \(windowIDs.count) windows, found \(matchingWindows.count) matches in \(content.windows.count) total windows")

            guard !matchingWindows.isEmpty else {
                Logger.screenCapture.warning("No matching windows found for IDs: \(windowIDs)")
                semaphore.signal()
                return
            }

            // If we have a single window, capture it directly
            if matchingWindows.count == 1, let window = matchingWindows.first {
                let filter = SCContentFilter(desktopIndependentWindow: window)
                let config = SCStreamConfiguration()
                config.width = Int(window.frame.width * 2) // Retina
                config.height = Int(window.frame.height * 2)
                config.scalesToFit = false
                config.showsCursor = false

                SCScreenshotManager.captureImage(contentFilter: filter, configuration: config) { image, captureError in
                    if let captureError = captureError {
                        Logger.screenCapture.warning("SCScreenshotManager.captureImage failed: \(captureError.localizedDescription)")
                    } else {
                        resultImage = image
                    }
                    semaphore.signal()
                }
            } else {
                // For multiple windows, capture each window individually and composite them
                // This avoids the sourceRect/contentRect issues with multi-window capture
                Logger.screenCapture.debug("Using individual window capture for \(matchingWindows.count) windows")

                // For now, just capture the first window to avoid the sourceRect error
                // A full implementation would composite multiple captures
                if let firstWindow = matchingWindows.first {
                    let filter = SCContentFilter(desktopIndependentWindow: firstWindow)
                    let config = SCStreamConfiguration()
                    config.width = Int(firstWindow.frame.width * 2)
                    config.height = Int(firstWindow.frame.height * 2)
                    config.scalesToFit = false
                    config.showsCursor = false

                    SCScreenshotManager.captureImage(contentFilter: filter, configuration: config) { image, captureError in
                        if let captureError = captureError {
                            Logger.screenCapture.warning("SCScreenshotManager single window capture failed: \(captureError.localizedDescription)")
                        } else {
                            resultImage = image
                        }
                        semaphore.signal()
                    }
                } else {
                    semaphore.signal()
                }
            }
        }

        _ = semaphore.wait(timeout: .now() + 2.0)
        return resultImage
    }

    /// Captures an image of a window.
    ///
    /// - Parameters:
    ///   - windowID: The identifier of the window to capture.
    ///   - screenBounds: The bounds to capture. Pass `nil` to capture the minimum rectangle that encloses the window.
    ///   - option: Options that specify the image to be captured.
    static func captureWindow(_ windowID: CGWindowID, screenBounds: CGRect? = nil, option: CGWindowImageOption = []) -> CGImage? {
        captureWindows([windowID], screenBounds: screenBounds, option: option)
    }
}

/// A protocol used to suppress deprecation warnings for the `CGWindowList` screen capture APIs.
///
/// ScreenCaptureKit doesn't support capturing composite images of offscreen menu bar items, but
/// this should be replaced once it does.
private protocol WindowListImage {
    init?(windowListFromArrayScreenBounds: CGRect, windowArray: CFArray, imageOption: CGWindowImageOption)
}

private extension WindowListImage {
    static func windowListImage(from screenBounds: CGRect, windowArray: CFArray, imageOption: CGWindowImageOption) -> Self? {
        Self(windowListFromArrayScreenBounds: screenBounds, windowArray: windowArray, imageOption: imageOption)
    }
}

extension CGImage: WindowListImage { }

// MARK: - Logger

private extension Logger {
    static let screenCapture = Logger(category: "ScreenCapture")
}
