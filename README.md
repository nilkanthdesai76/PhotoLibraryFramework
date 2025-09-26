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

## Requirements

- iOS 13.0+
- Swift 5.7+
- Xcode 14.0+

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/PhotoLibraryFramework.git", from: "1.0.0")
]
```

Or add it through Xcode:
1. File → Add Packages
2. Enter the repository URL
3. Select version and add to your target

## Usage

### Basic Implementation

```swift
import PhotoLibraryFramework

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Optional: Configure theme
        PLFFramework.shared.configure(with: MyThemeProvider())
    }
    
    @IBAction func selectPhotoTapped() {
        presentPhotoLibrary(
            delegate: self,
            mediaType: .images,
            selectionLimit: 5
        )
    }
}

extension ViewController: PhotoLibraryDelegate {
    func photoLibrary(didSelectAssets assets: [PHAsset]) {
        // Handle selected photos
        assets.processAssets { images in
            // Use processed images
        }
    }
    
    func photoLibrary(didCaptureImage image: UIImage) {
        // Handle captured photo
    }
    
    func photoLibrary(didCancel: Void) {
        // Handle cancellation
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

Main framework class for configuration.

```swift
PhotoLibraryFramework.shared.configure(with: themeProvider)
```

### PLFPhotoLibraryManager

Core manager for photo operations.

```swift
PLFPhotoLibraryManager.shared.presentPhotoPicker(
    delegate: self,
    from: viewController,
    mediaType: .imagesAndVideos,
    selectionLimit: 10
)
```

### Media Types

- `.images` - Images only
- `.videos` - Videos only  
- `.livePhotos` - Live Photos only
- `.imagesAndVideos` - Both images and videos

### Utility Classes

#### PLFPhotoUtilities
- `resizeImage(_:to:)` - Resize images
- `compressImage(_:quality:)` - Compress images
- `getMetadata(for:)` - Get asset metadata

#### PLFPermissionManager
- `photoLibraryAuthorizationStatus()` - Check photo permissions
- `cameraAuthorizationStatus()` - Check camera permissions
- `areAllPermissionsGranted()` - Check all permissions

## License

MIT License - see LICENSE file for details.