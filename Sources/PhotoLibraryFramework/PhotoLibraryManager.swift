import Foundation
import UIKit
import Photos
import PhotosUI
import AVFoundation
import UniformTypeIdentifiers

// MARK: - Public Configuration
@objc public enum MediaType: Int, CaseIterable {
    case images
    case videos
    case livePhotos
    case imagesAndVideos
    
    @available(iOS 14.0, *)
    internal var phPickerFilter: PHPickerFilter? {
        switch self {
        case .images:
            return .images
        case .videos:
            return .videos
        case .livePhotos:
            return .livePhotos
        case .imagesAndVideos:
            return .any(of: [.images, .videos])
        }
    }
}

// MARK: - Framework Messages
public struct Messages {
    public struct Errors {
        public static var cameraPermission = "Please enable camera permission in settings"
        public static var photoLibraryDenied = "Please enable photo library permission in settings"
        public static var cameraUnavailable = "Camera not found"
        public static var selectionLimit = "Selection limit must be greater than 0!"
        public static var iCloudAuthenticationRequired = "iCloud authentication is required to download this photo. Please sign in to iCloud in Settings."
        public static var iCloudDownloadFailed = "Failed to download photo from iCloud. Please check your internet connection and try again."
        public static var iCloudNotSignedIn = "Please sign in to iCloud in Settings to access your photo library."
    }
    
    public struct Actions {
        public static var camera = "Take photo"
        public static var gallery = "Import from gallery"
        public static var cancel = "Cancel"
        public static var settings = "Settings"
        public static var ok = "Ok"
        public static var retry = "Retry"
    }
    
    public struct Prompts {
        public static var chooseSource = "Select photo from"
    }
}

// MARK: - Public Delegate Protocol
@objc public protocol PhotoLibraryDelegate: AnyObject {
    /// Called when user takes a photo from camera
    func photoLibrary(didCaptureImage image: UIImage)
    
    /// Called when user selects photos from library
    func photoLibrary(didSelectAssets assets: [PHAsset])
    
    /// Called when user cancels the picker
    func photoLibraryDidCancel()
    
    // Optional iCloud support methods
    @objc optional func photoLibrary(didStartDownloadingFromCloud asset: PHAsset)
    @objc optional func photoLibrary(downloadProgress progress: Double, for asset: PHAsset)
    @objc optional func photoLibrary(didFinishDownloading image: UIImage?, for asset: PHAsset, error: Error?)
    @objc optional func photoLibrary(iCloudAuthenticationRequired asset: PHAsset, retryHandler: @escaping () -> Void)
}

// MARK: - Main Manager Class
@objc public final class PhotoLibraryManager: NSObject {
    
    // MARK: - Public Properties
    @objc public static let shared = PhotoLibraryManager()
    
    // MARK: - Private Properties
    private weak var delegate: PhotoLibraryDelegate?
    private weak var presentingViewController: UIViewController?
    private var imagePicker: UIImagePickerController?
    private var sourceView: UIView?
    private var sourceRect: CGRect = .zero
    
    private var currentMediaType: MediaType = .imagesAndVideos
    private var currentSelectionLimit: Int = 1
    
    private override init() {
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Open photo picker with camera and gallery options
    /// - Parameters:
    ///   - delegate: Delegate to receive callbacks
    ///   - viewController: View controller to present from
    ///   - mediaType: Type of media to select
    ///   - selectionLimit: Maximum number of items to select (1 for single selection)
    ///   - sourceView: Source view for iPad popover presentation
    ///   - sourceRect: Source rect for iPad popover presentation
    @objc public static func openPicker(
        delegate: PhotoLibraryDelegate,
        from viewController: UIViewController,
        mediaType: MediaType = .imagesAndVideos,
        selectionLimit: Int = 1,
        sourceView: UIView? = nil,
        sourceRect: CGRect = .zero
    ) {
        shared.presentPhotoPicker(
            delegate: delegate,
            from: viewController,
            mediaType: mediaType,
            selectionLimit: selectionLimit,
            sourceView: sourceView,
            sourceRect: sourceRect
        )
    }
    
    /// Internal method to present photo picker
    private func presentPhotoPicker(
        delegate: PhotoLibraryDelegate,
        from viewController: UIViewController,
        mediaType: MediaType = .imagesAndVideos,
        selectionLimit: Int = 1,
        sourceView: UIView? = nil,
        sourceRect: CGRect = .zero
    ) {
        guard selectionLimit > 0 else {
            assertionFailure(Messages.Errors.selectionLimit)
            return
        }
        
        self.delegate = delegate
        self.presentingViewController = viewController
        self.currentMediaType = mediaType
        self.currentSelectionLimit = selectionLimit
        self.sourceView = sourceView ?? viewController.view
        self.sourceRect = sourceRect
        
        presentSourceSelectionAlert()
    }
    
    /// Convert PHAsset to UIImage asynchronously with iCloud support (async/await version)
    /// - Parameters:
    ///   - asset: PHAsset to convert
    ///   - size: Target size (nil for full resolution)
    /// - Returns: UIImage if successful
    @available(iOS 13.0, *)
    public func getImage(from asset: PHAsset, targetSize size: CGSize? = nil) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            getImage(from: asset, targetSize: size) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
    
    /// Convert PHAsset to UIImage asynchronously with iCloud support
    /// - Parameters:
    ///   - asset: PHAsset to convert
    ///   - size: Target size (nil for full resolution)
    ///   - completion: Completion handler with image and info
    public func getImage(
        from asset: PHAsset,
        targetSize size: CGSize? = nil,
        completion: @escaping (UIImage?, [AnyHashable: Any]?) -> Void
    ) {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isSynchronous = false
        
        options.progressHandler = { [weak self] progress, error, stop, info in
            DispatchQueue.main.async {
                self?.delegate?.photoLibrary?(downloadProgress: progress, for: asset)
                
                if let error = error {
                    if self?.isICloudAuthenticationError(error) == true {
                        stop.pointee = true
                        self?.delegate?.photoLibrary?(iCloudAuthenticationRequired: asset) {
                            self?.getImage(from: asset, targetSize: size, completion: completion)
                        }
                        return
                    }
                }
            }
        }
        
        let targetSize = size ?? CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
        
        manager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options) { [weak self] image, info in
            DispatchQueue.main.async {
                if let error = info?[PHImageErrorKey] as? Error {
                    if self?.isICloudAuthenticationError(error) == true {
                        self?.delegate?.photoLibrary?(iCloudAuthenticationRequired: asset) {
                            self?.getImage(from: asset, targetSize: size, completion: completion)
                        }
                        return
                    }
                }
                
                self?.delegate?.photoLibrary?(didFinishDownloading: image, for: asset, error: info?[PHImageErrorKey] as? Error)
                completion(image, info)
            }
        }
    }
    
    /// Check if PHAsset is stored in iCloud
    /// - Parameters:
    ///   - asset: PHAsset to check
    ///   - completion: Completion handler with boolean result
    @objc public func isAssetInCloud(_ asset: PHAsset, completion: @escaping (Bool) -> Void) {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = false
        options.isSynchronous = false
        
        manager.requestImage(for: asset, targetSize: CGSize(width: 1, height: 1), contentMode: .aspectFit, options: options) { _, info in
            DispatchQueue.main.async {
                let isInCloud = (info?[PHImageResultIsInCloudKey] as? Bool) ?? false
                completion(isInCloud)
            }
        }
    }
    
    /// Process multiple PHAssets with progress tracking
    /// - Parameters:
    ///   - assets: Array of PHAssets to process
    ///   - targetSize: Target size for images
    ///   - completion: Completion handler with array of processed images
    public func processAssets(
        _ assets: [PHAsset],
        targetSize: CGSize? = nil,
        completion: @escaping ([UIImage]) -> Void
    ) {
        var processedImages: [UIImage] = []
        let group = DispatchGroup()
        
        for asset in assets {
            group.enter()
            
            isAssetInCloud(asset) { [weak self] isInCloud in
                if isInCloud {
                    self?.delegate?.photoLibrary?(didStartDownloadingFromCloud: asset)
                }
                
                self?.getImage(from: asset, targetSize: targetSize) { image, info in
                    defer { group.leave() }
                    
                    if let image = image {
                        processedImages.append(image)
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            completion(processedImages)
        }
    }
}

// MARK: - Private Methods
private extension PhotoLibraryManager {
    
    func presentSourceSelectionAlert() {
        let alert = UIAlertController(
            title: nil,
            message: Messages.Prompts.chooseSource,
            preferredStyle: .actionSheet
        )
        
        // Camera action
        alert.addAction(UIAlertAction(title: Messages.Actions.camera, style: .default) { [weak self] _ in
            self?.checkCameraPermission()
        })
        
        // Gallery action
        alert.addAction(UIAlertAction(title: Messages.Actions.gallery, style: .default) { [weak self] _ in
            self?.checkPhotoLibraryPermission()
        })
        
        // Cancel action
        alert.addAction(UIAlertAction(title: Messages.Actions.cancel, style: .cancel) { [weak self] _ in
            self?.delegate?.photoLibraryDidCancel()
        })
        
        // Configure popover for iPad
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = sourceView
            popoverController.sourceRect = sourceRect.isEmpty ? sourceView?.bounds ?? .zero : sourceRect
        }
        
        // Apply theme
        let themeStyle = ThemeManager.shared.currentUserInterfaceStyle
        if themeStyle != .unspecified {
            alert.overrideUserInterfaceStyle = themeStyle
        }
        
        presentingViewController?.present(alert, animated: true)
    }
    
    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            openCamera()
        case .denied, .restricted:
            showPermissionAlert(for: .camera)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.openCamera()
                    } else {
                        self?.showPermissionAlert(for: .camera)
                    }
                }
            }
        @unknown default:
            showPermissionAlert(for: .camera)
        }
    }
    
    func checkPhotoLibraryPermission() {
        if #available(iOS 14.0, *) {
            switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
            case .authorized:
                openPhotoLibrary()
            case .limited:
                openPhotoLibrary()
            case .denied, .restricted:
                showPermissionAlert(for: .photoLibrary)
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
                    DispatchQueue.main.async {
                        switch status {
                        case .authorized, .limited:
                            self?.openPhotoLibrary()
                        default:
                            self?.showPermissionAlert(for: .photoLibrary)
                        }
                    }
                }
            @unknown default:
                showPermissionAlert(for: .photoLibrary)
            }
        } else {
            // iOS 13 fallback
            switch PHPhotoLibrary.authorizationStatus() {
            case .authorized:
                openPhotoLibrary()
            case .denied, .restricted:
                showPermissionAlert(for: .photoLibrary)
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization { [weak self] status in
                    DispatchQueue.main.async {
                        switch status {
                        case .authorized:
                            self?.openPhotoLibrary()
                        default:
                            self?.showPermissionAlert(for: .photoLibrary)
                        }
                    }
                }
            @unknown default:
                showPermissionAlert(for: .photoLibrary)
            }
        }
    }
    
    func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showAlert(
                title: "Error",
                message: Messages.Errors.cameraUnavailable,
                actions: [Messages.Actions.ok]
            )
            return
        }
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        
        // Apply theme
        let themeStyle = ThemeManager.shared.currentUserInterfaceStyle
        if themeStyle != .unspecified {
            picker.overrideUserInterfaceStyle = themeStyle
        }
        
        imagePicker = picker
        presentingViewController?.present(picker, animated: true)
    }
    
    func openPhotoLibrary() {
        if #available(iOS 14.0, *) {
            var config = PHPickerConfiguration(photoLibrary: .shared())
            config.selectionLimit = currentSelectionLimit
            config.filter = currentMediaType.phPickerFilter
            
            if #available(iOS 15.0, *) {
                config.selection = .ordered
            }
            
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = self
            
            // Apply theme
            let themeStyle = ThemeManager.shared.currentUserInterfaceStyle
            if themeStyle != .unspecified {
                picker.overrideUserInterfaceStyle = themeStyle
            }
            
            presentingViewController?.present(picker, animated: true)
        } else {
            // Fallback to UIImagePickerController for iOS 13
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .photoLibrary
            picker.mediaTypes = getMediaTypes()
            
            // Apply theme
            let themeStyle = ThemeManager.shared.currentUserInterfaceStyle
            if themeStyle != .unspecified {
                picker.overrideUserInterfaceStyle = themeStyle
            }
            
            presentingViewController?.present(picker, animated: true)
        }
    }
    
    private func getMediaTypes() -> [String] {
        switch currentMediaType {
        case .images:
            return ["public.image"]
        case .videos:
            return ["public.movie"]
        case .livePhotos:
            return ["public.image"]
        case .imagesAndVideos:
            return ["public.image", "public.movie"]
        }
    }
    
    enum PermissionType {
        case camera
        case photoLibrary
        
        var errorMessage: String {
            switch self {
            case .camera:
                return Messages.Errors.cameraPermission
            case .photoLibrary:
                return Messages.Errors.photoLibraryDenied
            }
        }
    }
    
    func showPermissionAlert(for type: PermissionType) {
        showAlert(
            title: "Permission Required",
            message: type.errorMessage,
            actions: [Messages.Actions.settings, Messages.Actions.cancel]
        ) { [weak self] action in
            if action == Messages.Actions.settings {
                self?.openSettings()
            } else {
                self?.delegate?.photoLibraryDidCancel()
            }
        }
    }
    
    func showAlert(
        title: String?,
        message: String?,
        actions: [String],
        completion: ((String) -> Void)? = nil
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        for actionTitle in actions {
            let style: UIAlertAction.Style = actionTitle == Messages.Actions.cancel ? .cancel : .default
            alert.addAction(UIAlertAction(title: actionTitle, style: style) { _ in
                completion?(actionTitle)
            })
        }
        
        // Apply theme
        let themeStyle = ThemeManager.shared.currentUserInterfaceStyle
        if themeStyle != .unspecified {
            alert.overrideUserInterfaceStyle = themeStyle
        }
        
        presentingViewController?.present(alert, animated: true)
    }
    
    func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString),
           UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL)
        }
    }
    
    func isICloudAuthenticationError(_ error: Error?) -> Bool {
        guard let error = error as NSError? else { return false }
        
        // Check for CloudPhotoLibraryErrorDomain with code 1006 (authentication failure)
        if error.domain == "CloudPhotoLibraryErrorDomain" && error.code == 1006 {
            return true
        }
        
        // Check for CKErrorDomain with code 9 (user rejected authentication)
        if error.domain == "CKErrorDomain" && error.code == 9 {
            return true
        }
        
        // Check underlying errors
        if let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError {
            return isICloudAuthenticationError(underlyingError)
        }
        
        return false
    }
}

// MARK: - UIImagePickerControllerDelegate
extension PhotoLibraryManager: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let image = info[.originalImage] as? UIImage {
            delegate?.photoLibrary(didCaptureImage: image)
        }
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        delegate?.photoLibraryDidCancel()
    }
}

// MARK: - PHPickerViewControllerDelegate
@available(iOS 14.0, *)
extension PhotoLibraryManager: PHPickerViewControllerDelegate {
    
    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard !results.isEmpty else {
            delegate?.photoLibraryDidCancel()
            return
        }
        
        let identifiers = results.compactMap { $0.assetIdentifier }
        var assets: [PHAsset] = []
        
        for identifier in identifiers {
            let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
            if let asset = fetchResult.firstObject {
                assets.append(asset)
            }
        }
        
        delegate?.photoLibrary(didSelectAssets: assets)
    }
}