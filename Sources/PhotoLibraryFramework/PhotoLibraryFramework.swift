import Foundation
import UIKit

// MARK: - Public Framework Interface
@objc public class PLFFramework: NSObject {
    
    /// Shared instance for singleton access
    @objc public static let shared = PLFFramework()
    
    /// Framework version
    @objc public static let frameworkVersion = "1.0.0"
    
    private override init() {
        super.init()
    }
    
    /// Configure the framework with custom theme (optional)
    @objc public func configure(with themeProvider: PLFThemeProvider? = nil) {
        if let themeProvider = themeProvider {
            PLFThemeManager.shared.setThemeProvider(themeProvider)
        }
    }
}

// MARK: - Theme Management Protocol
@objc public protocol PLFThemeProvider {
    var userInterfaceStyle: UIUserInterfaceStyle { get }
    var isDarkMode: Bool { get }
}

// Default theme provider
@objc public class PLFDefaultThemeProvider: NSObject, PLFThemeProvider {
    public var userInterfaceStyle: UIUserInterfaceStyle = .unspecified
    public var isDarkMode: Bool {
        if userInterfaceStyle == .unspecified {
            return UITraitCollection.current.userInterfaceStyle == .dark
        }
        return userInterfaceStyle == .dark
    }
}

// Internal theme manager
internal class PLFThemeManager {
    static let shared = PLFThemeManager()
    private var themeProvider: PLFThemeProvider = PLFDefaultThemeProvider()
    
    func setThemeProvider(_ provider: PLFThemeProvider) {
        themeProvider = provider
    }
    
    var currentUserInterfaceStyle: UIUserInterfaceStyle {
        return themeProvider.userInterfaceStyle
    }
    
    var isDarkMode: Bool {
        return themeProvider.isDarkMode
    }
}