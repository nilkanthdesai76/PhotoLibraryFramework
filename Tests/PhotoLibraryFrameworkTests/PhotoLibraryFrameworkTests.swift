import XCTest
@testable import PhotoLibraryFramework

final class PhotoLibraryFrameworkTests: XCTestCase {
    
    func testFrameworkInitialization() {
        let framework = PLFFramework.shared
        XCTAssertNotNil(framework)
        XCTAssertEqual(PLFFramework.frameworkVersion, "1.0.0")
    }
    
    func testManagerInitialization() {
        let manager = PLFPhotoLibraryManager.shared
        XCTAssertNotNil(manager)
    }
    
    func testPermissionManager() {
        let photoStatus = PLFPermissionManager.photoLibraryAuthorizationStatus()
        let cameraStatus = PLFPermissionManager.cameraAuthorizationStatus()
        
        // Just test that these don't crash
        XCTAssertTrue(photoStatus.rawValue >= 0)
        XCTAssertTrue(cameraStatus.rawValue >= 0)
    }
    
    func testPhotoUtilities() {
        // Test image resizing with a simple 1x1 image
        let image = UIImage(systemName: "photo") ?? UIImage()
        let resized = PLFPhotoUtilities.resizeImage(image, to: CGSize(width: 100, height: 100))
        XCTAssertNotNil(resized)
    }
}