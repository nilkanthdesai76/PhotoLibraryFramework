#!/bin/bash

# Build script for PhotoLibraryFramework XCFramework

set -e

FRAMEWORK_NAME="PhotoLibraryFramework"
BUILD_DIR="build"
XCFRAMEWORK_DIR="xcframework"

# Clean previous builds
rm -rf $BUILD_DIR
rm -rf $XCFRAMEWORK_DIR
mkdir -p $BUILD_DIR
mkdir -p $XCFRAMEWORK_DIR

echo "Building PhotoLibraryFramework XCFramework..."

# Build for iOS Device
echo "Building for iOS Device..."
xcodebuild archive \
    -scheme $FRAMEWORK_NAME \
    -destination "generic/platform=iOS" \
    -archivePath "$BUILD_DIR/ios.xcarchive" \
    -sdk iphoneos \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# Build for iOS Simulator
echo "Building for iOS Simulator..."
xcodebuild archive \
    -scheme $FRAMEWORK_NAME \
    -destination "generic/platform=iOS Simulator" \
    -archivePath "$BUILD_DIR/ios_simulator.xcarchive" \
    -sdk iphonesimulator \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# Create XCFramework
echo "Creating XCFramework..."
xcodebuild -create-xcframework \
    -framework "$BUILD_DIR/ios.xcarchive/Products/Library/Frameworks/$FRAMEWORK_NAME.framework" \
    -framework "$BUILD_DIR/ios_simulator.xcarchive/Products/Library/Frameworks/$FRAMEWORK_NAME.framework" \
    -output "$XCFRAMEWORK_DIR/$FRAMEWORK_NAME.xcframework"

echo "✅ XCFramework created successfully at $XCFRAMEWORK_DIR/$FRAMEWORK_NAME.xcframework"

# Create zip for distribution
echo "Creating distribution zip..."
cd $XCFRAMEWORK_DIR
zip -r "$FRAMEWORK_NAME.xcframework.zip" "$FRAMEWORK_NAME.xcframework"
cd ..

echo "✅ Distribution zip created at $XCFRAMEWORK_DIR/$FRAMEWORK_NAME.xcframework.zip"
echo "🎉 Build completed successfully!"