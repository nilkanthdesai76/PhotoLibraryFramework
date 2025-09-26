import Foundation
import UIKit

// MARK: - Public Framework Interface
@objc public class PhotoLibraryFramework: NSObject {

  /// Shared instance for singleton access
  @objc public static let shared = PhotoLibraryFramework()

  /// Framework version
  @objc public static let frameworkVersion = "1.0.0"

  /// Get detailed version information
  @objc public static var versionInfo: [String: Any] {
    return [
      "version": frameworkVersion,
      "buildDate": "2024-12-19",
      "swiftVersion": "5.7+",
      "minimumIOSVersion": "13.0",
      "features": [
        "Camera Capture",
        "Photo Library Selection",
        "iCloud Support",
        "Theme Management",
        "Permission Handling",
        "Async/Await Support",
      ],
    ]
  }

  private override init() {
    super.init()
  }

  /// Configure the framework with custom theme (optional)
  @objc public func configure(with themeProvider: ThemeProvider? = nil) {
    if let themeProvider = themeProvider {
      ThemeManager.shared.setThemeProvider(themeProvider)
    }
  }
}

// MARK: - Theme Management Protocol
@objc public protocol ThemeProvider {
  var userInterfaceStyle: UIUserInterfaceStyle { get }
  var isDarkMode: Bool { get }
}

// Default theme provider
@objc public class DefaultThemeProvider: NSObject, ThemeProvider {
  public var userInterfaceStyle: UIUserInterfaceStyle = .unspecified
  public var isDarkMode: Bool {
    if userInterfaceStyle == .unspecified {
      return UITraitCollection.current.userInterfaceStyle == .dark
    }
    return userInterfaceStyle == .dark
  }
}

// Internal theme manager
internal class ThemeManager {
  static let shared = ThemeManager()
  private var themeProvider: ThemeProvider = DefaultThemeProvider()

  func setThemeProvider(_ provider: ThemeProvider) {
    themeProvider = provider
  }

  var currentUserInterfaceStyle: UIUserInterfaceStyle {
    return themeProvider.userInterfaceStyle
  }

  var isDarkMode: Bool {
    return themeProvider.isDarkMode
  }
}
