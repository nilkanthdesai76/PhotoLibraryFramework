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

### Simplified API (Recommended)

The framework now automatically uses the presenting view controller as the delegate, making the API much cleaner:

```swift
import PhotoLibraryFramework

class ViewController: UIViewController, PhotoLibraryDelegate {
    
    @IBAction func selectPhotoTapped() {
        // Just specify the view controller - it automatically becomes the delegate
        PhotoLibraryManager.openPicker(from: self, mediaType: .images, selectionLimit: 5)
    }
}

extension ViewController: PhotoLibraryDelegate {
    func photoLibrary(didSelectAssets assets: [PHAsset]) {
        // Handle selected photos
    }
    
    func photoLibrary(didCaptureImage image: UIImage) {
        // Handle captured photo
    }
    
    func photoLibraryDidCancel() {
        // Handle cancellation
    }
}
```

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
        // New simplified API - view controller automatically becomes delegate
        PhotoLibraryManager.openPicker(
            from: self,
            mediaType: .images,
            selectionLimit: 5
        )
    }
}

extension ViewController: PhotoLibraryDelegate {
    func photoLibrary(didSelectAssets assets: [PHAsset]) {
        // Handle multiple selected photos with PHAssets (preferred)
        if assets.isEmpty {
            print("Warning: Received empty assets array - check photo library permissions")
            return
        }
        processSelectedAssets(assets)
    }
    
    // Optional: Handle images when PHAssets are not available (fallback)
    func photoLibrary(didSelectImages images: [UIImage]) {
        // This is called when PHAssets are not available (limited photo access, etc.)
        print("Received \(images.count) images without PHAssets")
        handleSelectedImages(images)
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

// MARK: - Asset Processing Examples
extension ViewController {
    
    /// Process single asset with async/await
    private func processSingleAsset(_ asset: PHAsset) {
        Task {
            if let image = await PhotoLibraryManager.shared.getImage(from: asset) {
                DispatchQueue.main.async {
                    self.imageView.image = image
                }
            }
        }
    }
    
    /// Process multiple assets with progress tracking
    private func processSelectedAssets(_ assets: [PHAsset]) {
        guard !assets.isEmpty else { return }
        
        // Show loading indicator
        showLoadingIndicator()
        
        // Process all assets at once
        PhotoLibraryManager.shared.processAssets(assets) { [weak self] images in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.hideLoadingIndicator()
                
                // Handle processed images
                self.handleProcessedImages(images)
            }
        }
    }
    
    /// Handle processed images with validation
    private func handleProcessedImages(_ images: [UIImage]) {
        var validImages: [UIImage] = []
        
        // Filter images by size (example: max 4MB)
        for image in images {
            if let imageData = image.jpegData(compressionQuality: 0.8),
               imageData.count <= 4 * 1024 * 1024 { // 4MB limit
                validImages.append(image)
            } else {
                print("Image too large, skipping...")
            }
        }
        
        // Update UI with valid images
        updateImageCollection(validImages)
    }
    
    /// Individual asset processing with iCloud support
    private func processAssetWithiCloudSupport(_ asset: PHAsset) {
        // Check if asset is in iCloud
        PhotoLibraryManager.shared.isAssetInCloud(asset) { [weak self] isInCloud in
            if isInCloud {
                print("Asset is in iCloud, will download...")
            }
            
            // Get image with automatic iCloud handling
            PhotoLibraryManager.shared.getImage(from: asset) { image, info in
                DispatchQueue.main.async {
                    if let image = image {
                        self?.imageView.image = image
                    }
                }
            }
        }
    }
}
```

### Multiple Selection with iCloud Support

```swift
class ViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    private var selectedImages: [UIImage] = []
    private var isProcessing = false
    
    @IBAction func selectMultiplePhotosTapped() {
        PhotoLibraryManager.openPicker(
            from: self,
            mediaType: .images,
            selectionLimit: 10 // Allow up to 10 images
        )
    }
}

extension ViewController: PhotoLibraryDelegate {
    func photoLibrary(didSelectAssets assets: [PHAsset]) {
        processMultipleAssets(assets)
    }
    
    // MARK: - iCloud Progress Tracking
    func photoLibrary(didStartDownloadingFromCloud asset: PHAsset) {
        DispatchQueue.main.async {
            self.showProgressIndicator(message: "Downloading from iCloud...")
        }
    }
    
    func photoLibrary(downloadProgress progress: Double, for asset: PHAsset) {
        DispatchQueue.main.async {
            self.updateProgress(progress)
        }
    }
    
    func photoLibrary(didFinishDownloading image: UIImage?, for asset: PHAsset, error: Error?) {
        if let error = error {
            print("Download failed: \(error.localizedDescription)")
        } else if let image = image {
            print("Successfully downloaded image from iCloud")
        }
    }
    
    func photoLibrary(iCloudAuthenticationRequired asset: PHAsset, retryHandler: @escaping () -> Void) {
        showAlert(
            title: "iCloud Sign In Required",
            message: "Please sign in to iCloud in Settings to access your photos."
        ) { [weak self] in
            retryHandler()
        }
    }
}

// MARK: - Multiple Asset Processing
extension ViewController {
    private func processMultipleAssets(_ assets: [PHAsset]) {
        guard !isProcessing else { return }
        isProcessing = true
        
        showLoadingIndicator()
        
        // Method 1: Process all at once (recommended for multiple assets)
        PhotoLibraryManager.shared.processAssets(assets, targetSize: CGSize(width: 1024, height: 1024)) { [weak self] images in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.hideLoadingIndicator()
                self.isProcessing = false
                self.handleProcessedImages(images)
            }
        }
        
        // Method 2: Process individually with async/await (for more control)
        // processAssetsIndividually(assets)
    }
    
    private func processAssetsIndividually(_ assets: [PHAsset]) {
        Task {
            var processedImages: [UIImage] = []
            
            for (index, asset) in assets.enumerated() {
                // Update progress
                await MainActor.run {
                    updateProgress(Double(index) / Double(assets.count))
                }
                
                // Check if asset is in iCloud
                let isInCloud = await withCheckedContinuation { continuation in
                    PhotoLibraryManager.shared.isAssetInCloud(asset) { isInCloud in
                        continuation.resume(returning: isInCloud)
                    }
                }
                
                if isInCloud {
                    await MainActor.run {
                        showMessage("Downloading image \(index + 1) from iCloud...")
                    }
                }
                
                // Get image
                if let image = await PhotoLibraryManager.shared.getImage(from: asset, targetSize: CGSize(width: 1024, height: 1024)) {
                    processedImages.append(image)
                }
            }
            
            await MainActor.run {
                hideLoadingIndicator()
                isProcessing = false
                handleProcessedImages(processedImages)
            }
        }
    }
    
    private func handleProcessedImages(_ images: [UIImage]) {
        // Validate image sizes
        let validImages = images.filter { image in
            guard let imageData = image.jpegData(compressionQuality: 0.8) else { return false }
            let sizeMB = Double(imageData.count) / (1024 * 1024)
            
            if sizeMB > 4.0 {
                showAlert(message: "Image too large (max 4MB), skipping...")
                return false
            }
            return true
        }
        
        // Add to collection
        selectedImages.append(contentsOf: validImages)
        
        // Update UI
        collectionView.reloadData()
        
        // Show completion message
        showAlert(message: "Successfully processed \(validImages.count) images")
    }
}

// MARK: - UI Helper Methods
extension ViewController {
    private func showLoadingIndicator() {
        // Show your loading spinner
    }
    
    private func hideLoadingIndicator() {
        // Hide your loading spinner
    }
    
    private func showProgressIndicator(message: String) {
        // Show progress with message
    }
    
    private func updateProgress(_ progress: Double) {
        // Update progress bar (0.0 to 1.0)
    }
    
    private func showMessage(_ message: String) {
        print(message) // Or show toast/alert
    }
    
    private func showAlert(title: String = "Info", message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
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
    from: viewController, // viewController must conform to PhotoLibraryDelegate
    mediaType: .imagesAndVideos,
    selectionLimit: 10
)

// Alternative: Custom delegate (for advanced use cases)
PhotoLibraryManager.openPicker(
    delegate: customDelegate,
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

### Image Processing Utilities

```swift
// Resize and compress images
extension ViewController {
    private func processImageForUpload(_ image: UIImage) -> Data? {
        // Resize to maximum dimensions
        let maxSize = CGSize(width: 1024, height: 1024)
        guard let resizedImage = PhotoUtilities.resizeImage(image, to: maxSize) else {
            return nil
        }
        
        // Compress with quality
        return PhotoUtilities.compressImage(resizedImage, quality: 0.8)
    }
    
    private func getAssetMetadata(_ asset: PHAsset) {
        let metadata = PhotoUtilities.getMetadata(for: asset)
        
        print("Asset Info:")
        print("- Type: \(metadata["mediaType"] ?? "Unknown")")
        print("- Size: \(metadata["sizeInMB"] ?? 0) MB")
        print("- Dimensions: \(metadata["pixelWidth"] ?? 0) x \(metadata["pixelHeight"] ?? 0)")
        print("- Created: \(metadata["creationDate"] ?? "Unknown")")
        
        if let latitude = metadata["latitude"] as? Double,
           let longitude = metadata["longitude"] as? Double {
            print("- Location: \(latitude), \(longitude)")
        }
    }
}
```

### Permission Management

```swift
// Check and request permissions
extension ViewController {
    private func checkPermissions() {
        // Check current status
        let photoStatus = PermissionManager.photoLibraryAuthorizationStatus()
        let cameraStatus = PermissionManager.cameraAuthorizationStatus()
        
        print("Photo Library: \(photoStatus)")
        print("Camera: \(cameraStatus)")
        
        // Check if all permissions are granted
        if PermissionManager.areAllPermissionsGranted() {
            print("All permissions granted!")
        } else {
            requestMissingPermissions()
        }
    }
    
    private func requestMissingPermissions() {
        // Request photo library permission
        PermissionManager.requestPhotoLibraryPermission { status in
            DispatchQueue.main.async {
                print("Photo library permission: \(status)")
            }
        }
        
        // Request camera permission
        PermissionManager.requestCameraPermission { granted in
            DispatchQueue.main.async {
                print("Camera permission granted: \(granted)")
            }
        }
    }
}
```

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

## Troubleshooting

### Limited Photo Access Issue

**The Problem**: When users grant "Limited Photo Access", iOS shows the system photo picker that allows selecting from all photos, but the selected photos don't have PHAsset identifiers. This results in an empty assets array.

**Why This Happens**:
1. **Limited Access**: User selected "Select Photos" instead of "Allow Access to All Photos"
2. **System Behavior**: iOS shows full photo picker but doesn't provide asset identifiers for privacy
3. **Framework Limitation**: PHPickerViewController returns results without `assetIdentifier` for limited access

**Solutions**:

#### Option 1: Implement Fallback Delegate Method (Recommended)
```swift
extension ViewController: PhotoLibraryDelegate {
    func photoLibrary(didSelectAssets assets: [PHAsset]) {
        if assets.isEmpty {
            print("Empty assets - framework will call didSelectImages fallback")
            return
        }
        // Handle PHAssets normally (full access)
        processAssets(assets)
    }
    
    // Add this method to handle limited access
    func photoLibrary(didSelectImages images: [UIImage]) {
        print("Limited access: Received \(images.count) images without PHAssets")
        // Handle UIImages directly - same processing as PHAssets but with UIImages
        processImages(images)
    }
}
```

#### Option 2: Check Access Level and Guide User
```swift
@IBAction func selectPhotosTapped() {
    // Check access level first
    if #available(iOS 14.0, *) {
        if PhotoLibraryManager.hasLimitedPhotoAccess() {
            showLimitedAccessAlert()
            return
        }
    }
    
    // Proceed with normal picker
    PhotoLibraryManager.openPicker(from: self, mediaType: .images, selectionLimit: 5)
}

private func showLimitedAccessAlert() {
    let alert = UIAlertController(
        title: "Limited Photo Access",
        message: "For best experience, please allow access to all photos in Settings.",
        preferredStyle: .alert
    )
    
    alert.addAction(UIAlertAction(title: "Continue Anyway", style: .default) { _ in
        PhotoLibraryManager.openPicker(from: self, mediaType: .images, selectionLimit: 5)
    })
    
    alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    })
    
    present(alert, animated: true)
}
```

#### Option 3: Request Full Access
```swift
private func requestFullPhotoAccess() {
    if #available(iOS 14.0, *) {
        PhotoLibraryManager.requestFullPhotoAccess { status in
            switch status {
            case .authorized:
                print("Full access granted")
                self.openPhotoPicker()
            case .limited:
                print("Still limited access")
                self.handleLimitedAccess()
            default:
                print("Access denied")
            }
        }
    }
}
```

### Debug Information

Enable console logging to see detailed picker information:

```swift
// The framework automatically logs debug information to console
// Look for logs starting with "PHPicker:" or "PhotoLibrary:"
```

### Permission Checking

```swift
// Check current permissions
let status = PermissionManager.photoLibraryAuthorizationStatus()
print("Photo library status: \(status)")

if status == .limited {
    print("Limited access - some photos may not have PHAssets")
}
```

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