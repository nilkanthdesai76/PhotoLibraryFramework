# PhotoLibraryFramework

A comprehensive iOS framework for handling photo library operations, camera capture, and iCloud photo management.

## Features

- 📸 Camera capture with permission handling
- 🖼️ Photo library selection with multiple media types
- ☁️ iCloud photo download support with progress tracking
- 🎨 Theme support (light/dark mode)
- 📱 iPad popover support
- 🔒 Comprehensive permission management
- 🛠️ Utility functions for image processing
- 🏷️ Version-based dependency management

## Requirements

- iOS 13.0+
- Swift 5.7+
- Xcode 14.0+

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/nilkanthdesai76/PhotoLibraryFramework.git", from: "1.0.0")
]
```

Or add it through Xcode:
1. File → Add Packages
2. Enter the repository URL: `https://github.com/nilkanthdesai76/PhotoLibraryFramework.git`
3. Select version (recommended: use exact version or version range)
4. Add to your target

### Version Management

The framework uses semantic versioning. You can specify versions in several ways:

```swift
// Exact version
.package(url: "https://github.com/nilkanthdesai76/PhotoLibraryFramework.git", .exact("1.0.0"))

// Version range
.package(url: "https://github.com/nilkanthdesai76/PhotoLibraryFramework.git", "1.0.0"..<"2.0.0")

// From version (recommended for patch updates)
.package(url: "https://github.com/nilkanthdesai76/PhotoLibraryFramework.git", from: "1.0.0")
```

## Usage

### Basic Implementation

```swift
import PhotoLibraryFramework

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Optional: Configure theme
        PhotoLibraryFramework.shared.configure(with: MyThemeProvider())
    }
    
    @IBAction func selectPhotoTapped() {
        // New API - use PhotoLibraryManager.openPicker
        PhotoLibraryManager.openPicker(
            delegate: self,
            from: self,
            mediaType: .images,
            selectionLimit: 5
        )
    }
}

extension ViewController: PhotoLibraryDelegate {
    func photoLibrary(didSelectAssets assets: [PHAsset]) {
        // Handle selected photos with async/await
        guard let firstAsset = assets.first else { return }
        Task {
            if let image = await PhotoLibraryManager.shared.getImage(from: firstAsset) {
                DispatchQueue.main.async {
                    // Use the image
                    self.imageView.image = image
                }
            }
        }
    }
    
    func photoLibrary(didCaptureImage image: UIImage) {
        // Handle captured photo
        imageView.image = image
    }
    
    func photoLibraryDidCancel() {
        // Handle cancellation
        print("User cancelled photo selection")
    }
}
```

### Advanced Usage with iCloud Support

```swift
extension ViewController {
    func photoLibrary(didStartDownloadingFromCloud asset: PHAsset) {
        // Show loading indicator
    }
    
    func photoLibrary(downloadProgress progress: Double, for asset: PHAsset) {
        // Update progress bar
    }
    
    func photoLibrary(didFinishDownloading image: UIImage?, for asset: PHAsset, error: Error?) {
        // Handle download completion
    }
    
    func photoLibrary(iCloudAuthenticationRequired asset: PHAsset, retryHandler: @escaping () -> Void) {
        // Handle iCloud authentication
        showAlert(message: "Please sign in to iCloud") {
            retryHandler()
        }
    }
}
```

## API Reference

### PhotoLibraryFramework

Main framework class for configuration and versioning.

```swift
// Configure theme
PhotoLibraryFramework.shared.configure(with: themeProvider)

// Get framework version
let version = PhotoLibraryFramework.frameworkVersion
print("Using PhotoLibraryFramework v\(version)")
```

### PhotoLibraryManager

Core manager for photo operations with simplified API.

```swift
// Open photo picker (new simplified API)
PhotoLibraryManager.openPicker(
    delegate: self,
    from: viewController,
    mediaType: .imagesAndVideos,
    selectionLimit: 10
)

// Get image from asset (async/await)
let image = await PhotoLibraryManager.shared.getImage(from: asset)

// Get image from asset (completion handler)
PhotoLibraryManager.shared.getImage(from: asset) { image, info in
    // Handle image
}
```

### Media Types

- `.images` - Images only
- `.videos` - Videos only  
- `.livePhotos` - Live Photos only
- `.imagesAndVideos` - Both images and videos

### Utility Classes

#### PhotoUtilities
- `resizeImage(_:to:)` - Resize images to target size
- `compressImage(_:quality:)` - Compress images with quality
- `getMetadata(for:)` - Get comprehensive asset metadata

#### PermissionManager
- `photoLibraryAuthorizationStatus()` - Check photo library permissions
- `cameraAuthorizationStatus()` - Check camera permissions
- `areAllPermissionsGranted()` - Check if all permissions are granted
- `requestPhotoLibraryPermission(_:)` - Request photo library access
- `requestCameraPermission(_:)` - Request camera access

### Theme Management

```swift
// Custom theme provider
class MyThemeProvider: ThemeProvider {
    var userInterfaceStyle: UIUserInterfaceStyle = .dark
    var isDarkMode: Bool = true
}

// Configure framework with theme
PhotoLibraryFramework.shared.configure(with: MyThemeProvider())
```

## Migration from Previous Versions

If you're upgrading from a version with PLF prefixes, here are the key changes:

### API Changes
- `PLFPhotoLibraryManager.shared.presentPhotoPicker()` → `PhotoLibraryManager.openPicker()`
- `PLFPhotoUtilities` → `PhotoUtilities`
- `PLFPermissionManager` → `PermissionManager`
- `PLFFramework` → `PhotoLibraryFramework`
- `PLFThemeProvider` → `ThemeProvider`

### New Features in v1.0.0
- Simplified API with static methods
- Async/await support for modern Swift
- Better version management
- Improved documentation
- Cleaner naming conventions

## Version Information

```swift
// Get current version
let version = PhotoLibraryFramework.frameworkVersion
print("Framework version: \(version)")

// Get detailed version info
let info = PhotoLibraryFramework.versionInfo
print("Version info: \(info)")
```

## License

MIT License - see LICENSE file for details.