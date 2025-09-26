#!/bin/bash

# Build script for PhotoLibraryFramework XCFramework using Swift Package Manager

set -e

FRAMEWORK_NAME="PhotoLibraryFramework"
BUILD_DIR="build"
XCFRAMEWORK_DIR="xcframework"

# Clean previous builds
rm -rf $BUILD_DIR
rm -rf $XCFRAMEWORK_DIR
mkdir -p $BUILD_DIR
mkdir -p $XCFRAMEWORK_DIR

echo "Building PhotoLibraryFramework XCFramework using Swift Package Manager..."

# Build for iOS Device
echo "Building for iOS Device..."
xcodebuild -scheme $FRAMEWORK_NAME \
    -destination "generic/platform=iOS" \
    -derivedDataPath "$BUILD_DIR/ios" \
    -configuration Release \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    SKIP_INSTALL=NO \
    build

# Build for iOS Simulator
echo "Building for iOS Simulator..."
xcodebuild -scheme $FRAMEWORK_NAME \
    -destination "generic/platform=iOS Simulator" \
    -derivedDataPath "$BUILD_DIR/ios_simulator" \
    -configuration Release \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    SKIP_INSTALL=NO \
    build

# Find the built frameworks
IOS_FRAMEWORK_PATH=$(find "$BUILD_DIR/ios" -name "$FRAMEWORK_NAME.framework" -type d | head -1)
SIMULATOR_FRAMEWORK_PATH=$(find "$BUILD_DIR/ios_simulator" -name "$FRAMEWORK_NAME.framework" -type d | head -1)

if [ -z "$IOS_FRAMEWORK_PATH" ] || [ -z "$SIMULATOR_FRAMEWORK_PATH" ]; then
    echo "❌ Could not find built frameworks"
    echo "iOS Framework: $IOS_FRAMEWORK_PATH"
    echo "Simulator Framework: $SIMULATOR_FRAMEWORK_PATH"
    exit 1
fi

echo "Found frameworks:"
echo "iOS: $IOS_FRAMEWORK_PATH"
echo "Simulator: $SIMULATOR_FRAMEWORK_PATH"

# Create XCFramework
echo "Creating XCFramework..."
xcodebuild -create-xcframework \
    -framework "$IOS_FRAMEWORK_PATH" \
    -framework "$SIMULATOR_FRAMEWORK_PATH" \
    -output "$XCFRAMEWORK_DIR/$FRAMEWORK_NAME.xcframework"

echo "✅ XCFramework created successfully at $XCFRAMEWORK_DIR/$FRAMEWORK_NAME.xcframework"

# Create zip for distribution
echo "Creating distribution zip..."
cd $XCFRAMEWORK_DIR
zip -r "$FRAMEWORK_NAME.xcframework.zip" "$FRAMEWORK_NAME.xcframework"
cd ..

echo "✅ Distribution zip created at $XCFRAMEWORK_DIR/$FRAMEWORK_NAME.xcframework.zip"
echo "🎉 Build completed successfully!"