import UIKit
import PhotoLibraryFramework

// MARK: - Example View Controller
class ExampleViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var selectButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureFramework()
    }
    
    private func setupUI() {
        title = "PhotoLibrary Example"
        
        selectButton.setTitle("Select Photos", for: .normal)
        cameraButton.setTitle("Take Photo", for: .normal)
        
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .systemGray6
    }
    
    private func configureFramework() {
        // Optional: Configure with custom theme
        PLFFramework.shared.configure(with: CustomThemeProvider())
    }
    
    // MARK: - Actions
    
    @IBAction func selectPhotosButtonTapped(_ sender: UIButton) {
        presentPhotoLibrary(
            delegate: self,
            mediaType: .images,
            selectionLimit: 5,
            sourceView: sender,
            sourceRect: sender.bounds
        )
    }
    
    @IBAction func takePhotoButtonTapped(_ sender: UIButton) {
        presentPhotoLibrary(
            delegate: self,
            mediaType: .images,
            selectionLimit: 1,
            sourceView: sender,
            sourceRect: sender.bounds
        )
    }
}

// MARK: - PhotoLibraryDelegate
extension ExampleViewController: PhotoLibraryDelegate {
    
    func photoLibrary(didSelectAssets assets: [PHAsset]) {
        print("Selected \(assets.count) assets")
        
        // Process the first asset for display
        guard let firstAsset = assets.first else { return }
        
        firstAsset.getImage(targetSize: CGSize(width: 300, height: 300)) { [weak self] image in
            DispatchQueue.main.async {
                self?.imageView.image = image
            }
        }
        
        // Process all assets
        assets.processAssets(targetSize: CGSize(width: 300, height: 300)) { images in
            print("Processed \(images.count) images")
            // Handle all processed images
        }
    }
    
    func photoLibrary(didCaptureImage image: UIImage) {
        print("Captured image: \(image.size)")
        imageView.image = image
    }
    
    func photoLibraryDidCancel() {
        print("Photo selection cancelled")
    }
    
    // MARK: - Optional iCloud Support Methods
    
    func photoLibrary(didStartDownloadingFromCloud asset: PHAsset) {
        print("Started downloading from iCloud: \(asset.localIdentifier)")
        // Show loading indicator
    }
    
    func photoLibrary(downloadProgress progress: Double, for asset: PHAsset) {
        print("Download progress: \(Int(progress * 100))%")
        // Update progress bar
    }
    
    func photoLibrary(didFinishDownloading image: UIImage?, for asset: PHAsset, error: Error?) {
        if let error = error {
            print("Download failed: \(error.localizedDescription)")
        } else {
            print("Download completed successfully")
        }
    }
    
    func photoLibrary(iCloudAuthenticationRequired asset: PHAsset, retryHandler: @escaping () -> Void) {
        let alert = UIAlertController(
            title: "iCloud Sign In Required",
            message: "Please sign in to iCloud in Settings to access this photo.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { _ in
            retryHandler()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
}

// MARK: - Custom Theme Provider
class CustomThemeProvider: PLFThemeProvider {
    var userInterfaceStyle: UIUserInterfaceStyle {
        // Follow system theme
        return .unspecified
    }
    
    var isDarkMode: Bool {
        return UITraitCollection.current.userInterfaceStyle == .dark
    }
}

// MARK: - Advanced Usage Examples
extension ExampleViewController {
    
    func advancedUsageExamples() {
        // Check permissions
        let hasPermissions = PLFPermissionManager.areAllPermissionsGranted()
        print("Has all permissions: \(hasPermissions)")
        
        // Request permissions manually
        PLFPermissionManager.requestPhotoLibraryPermission { status in
            print("Photo library permission: \(status)")
        }
        
        PLFPermissionManager.requestCameraPermission { granted in
            print("Camera permission granted: \(granted)")
        }
        
        // Utility functions
        if let image = imageView.image {
            // Resize image
            let resizedImage = PLFPhotoUtilities.resizeImage(image, to: CGSize(width: 100, height: 100))
            
            // Compress image
            let compressedData = PLFPhotoUtilities.compressImage(image, quality: 0.8)
            print("Compressed image size: \(compressedData?.count ?? 0) bytes")
        }
        
        // Asset metadata
        // Assuming you have a PHAsset
        // let metadata = PLFPhotoUtilities.getMetadata(for: asset)
        // print("Asset metadata: \(metadata)")
    }
}

// MARK: - SwiftUI Integration Example
import SwiftUI

@available(iOS 14.0, *)
struct PhotoLibrarySwiftUIView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> ExampleViewController {
        let controller = ExampleViewController()
        return controller
    }
    
    func updateUIViewController(_ uiViewController: ExampleViewController, context: Context) {
        // Update if needed
    }
}

// MARK: - Usage in SwiftUI
@available(iOS 14.0, *)
struct ContentView: View {
    @State private var selectedImage: UIImage?
    @State private var showingPhotoPicker = false
    
    var body: some View {
        VStack {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 300)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 300)
                    .overlay(Text("No Image Selected"))
            }
            
            Button("Select Photo") {
                showingPhotoPicker = true
            }
            .padding()
        }
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoLibrarySwiftUIView(selectedImage: $selectedImage)
        }
    }
}