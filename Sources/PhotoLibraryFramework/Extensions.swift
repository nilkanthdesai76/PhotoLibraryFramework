import Foundation
import UIKit
import Photos

// MARK: - Convenience Extensions

public extension PHAsset {
    
    /// Get image from PHAsset using the framework manager (async/await version)
    /// - Parameter targetSize: Target size for the image
    /// - Returns: UIImage if successful
    @available(iOS 13.0, *)
    func getImage(targetSize: CGSize? = nil) async -> UIImage? {
        return await PhotoLibraryManager.shared.getImage(from: self, targetSize: targetSize)
    }
    
    /// Get image from PHAsset using the framework manager
    /// - Parameters:
    ///   - targetSize: Target size for the image
    ///   - completion: Completion handler
    func getImage(targetSize: CGSize? = nil, completion: @escaping (UIImage?) -> Void) {
        PhotoLibraryManager.shared.getImage(from: self, targetSize: targetSize) { image, _ in
            completion(image)
        }
    }
    
    /// Check if this asset is stored in iCloud
    /// - Parameter completion: Completion handler with boolean result
    func isInCloud(completion: @escaping (Bool) -> Void) {
        PhotoLibraryManager.shared.isAssetInCloud(self, completion: completion)
    }
    
    /// Get asset creation date as formatted string
    var creationDateString: String? {
        guard let date = creationDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    /// Get asset media type as readable string
    var mediaTypeString: String {
        switch mediaType {
        case .image:
            return "Image"
        case .video:
            return "Video"
        case .audio:
            return "Audio"
        case .unknown:
            return "Unknown"
        @unknown default:
            return "Unknown"
        }
    }
    
    /// Get asset size in MB
    var sizeInMB: Double {
        guard let resource = PHAssetResource.assetResources(for: self).first else { return 0.0 }
        if let size = resource.value(forKey: "fileSize") as? Int64 {
            return Double(size) / (1024.0 * 1024.0)
        }
        return 0.0
    }
}

public extension Array where Element == PHAsset {
    
    /// Process all assets in the array using the framework manager
    /// - Parameters:
    ///   - targetSize: Target size for images
    ///   - completion: Completion handler with processed images
    func processAssets(targetSize: CGSize? = nil, completion: @escaping ([UIImage]) -> Void) {
        PhotoLibraryManager.shared.processAssets(self, targetSize: targetSize, completion: completion)
    }
    
    /// Get total size of all assets in MB
    var totalSizeInMB: Double {
        return self.reduce(0) { $0 + $1.sizeInMB }
    }
    
    /// Filter assets by media type
    /// - Parameter mediaType: PHAssetMediaType to filter by
    /// - Returns: Filtered array of assets
    func filtered(by mediaType: PHAssetMediaType) -> [PHAsset] {
        return self.filter { $0.mediaType == mediaType }
    }
}

public extension UIViewController {
    
    /// Convenience method to present photo picker (requires view controller to conform to PhotoLibraryDelegate)
    /// - Parameters:
    ///   - mediaType: Type of media to select
    ///   - selectionLimit: Maximum selection limit
    ///   - sourceView: Source view for popover (iPad)
    ///   - sourceRect: Source rect for popover (iPad)
    func presentPhotoLibrary(
        mediaType: MediaType = .imagesAndVideos,
        selectionLimit: Int = 1,
        sourceView: UIView? = nil,
        sourceRect: CGRect = .zero
    ) {
        guard let delegateViewController = self as? (UIViewController & PhotoLibraryDelegate) else {
            assertionFailure("View controller must conform to PhotoLibraryDelegate to use this convenience method")
            return
        }
        
        PhotoLibraryManager.openPicker(
            from: delegateViewController,
            mediaType: mediaType,
            selectionLimit: selectionLimit,
            sourceView: sourceView,
            sourceRect: sourceRect
        )
    }
}

// MARK: - Utility Classes

/// Utility class for common photo operations
@objc public class PhotoUtilities: NSObject {
    
    /// Resize image to target size
    /// - Parameters:
    ///   - image: Source image
    ///   - targetSize: Target size
    /// - Returns: Resized image
    @objc public static func resizeImage(_ image: UIImage, to targetSize: CGSize) -> UIImage? {
        let size = image.size
        
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        
        // Determine what side of the image we want to match
        let newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        // Create new image context
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    /// Compress image to specified quality
    /// - Parameters:
    ///   - image: Source image
    ///   - quality: Compression quality (0.0 to 1.0)
    /// - Returns: Compressed image data
    @objc public static func compressImage(_ image: UIImage, quality: CGFloat = 0.8) -> Data? {
        return image.jpegData(compressionQuality: quality)
    }
    
    /// Get image metadata
    /// - Parameter asset: PHAsset to get metadata from
    /// - Returns: Dictionary with metadata information
    @objc public static func getMetadata(for asset: PHAsset) -> [String: Any] {
        var metadata: [String: Any] = [:]
        
        metadata["localIdentifier"] = asset.localIdentifier
        metadata["mediaType"] = asset.mediaTypeString
        metadata["creationDate"] = asset.creationDateString
        metadata["pixelWidth"] = asset.pixelWidth
        metadata["pixelHeight"] = asset.pixelHeight
        metadata["duration"] = asset.duration
        metadata["sizeInMB"] = asset.sizeInMB
        
        if let location = asset.location {
            metadata["latitude"] = location.coordinate.latitude
            metadata["longitude"] = location.coordinate.longitude
        }
        
        return metadata
    }
}

/// Permission utility class
@objc public class PermissionManager: NSObject {
    
    /// Check current photo library permission status
    /// - Returns: Authorization status
    @objc public static func photoLibraryAuthorizationStatus() -> PHAuthorizationStatus {
        if #available(iOS 14.0, *) {
            return PHPhotoLibrary.authorizationStatus(for: .readWrite)
        } else {
            return PHPhotoLibrary.authorizationStatus()
        }
    }
    
    /// Check current camera permission status
    /// - Returns: Authorization status
    @objc public static func cameraAuthorizationStatus() -> AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    /// Request photo library permission
    /// - Parameter completion: Completion handler with status
    @objc public static func requestPhotoLibraryPermission(completion: @escaping (PHAuthorizationStatus) -> Void) {
        if #available(iOS 14.0, *) {
            PHPhotoLibrary.requestAuthorization(for: .readWrite, handler: completion)
        } else {
            PHPhotoLibrary.requestAuthorization(completion)
        }
    }
    
    /// Request camera permission
    /// - Parameter completion: Completion handler with granted status
    @objc public static func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video, completionHandler: completion)
    }
    
    /// Check if both permissions are granted
    /// - Returns: True if both camera and photo library permissions are granted
    @objc public static func areAllPermissionsGranted() -> Bool {
        let photoStatus = photoLibraryAuthorizationStatus()
        let cameraStatus = cameraAuthorizationStatus()
        
        var photoGranted = photoStatus == .authorized
        if #available(iOS 14.0, *) {
            photoGranted = photoStatus == .authorized || photoStatus == .limited
        }
        let cameraGranted = cameraStatus == .authorized
        
        return photoGranted && cameraGranted
    }
}