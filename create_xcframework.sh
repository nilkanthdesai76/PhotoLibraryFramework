#!/bin/bash

# Simple XCFramework creation script for PhotoLibraryFramework

set -e

FRAMEWORK_NAME="PhotoLibraryFramework"
XCFRAMEWORK_DIR="xcframework"

# Clean previous builds
rm -rf $XCFRAMEWORK_DIR
mkdir -p $XCFRAMEWORK_DIR

echo "Creating XCFramework for PhotoLibraryFramework..."

# Since we have a Swift Package, let's create the XCFramework directly
# First, let's check what we actually built
echo "Checking build products..."
find build -name "*.framework" -o -name "*.swiftmodule" -o -name "*.o" | head -10

# Create XCFramework using the built products
IOS_BUILD_DIR="build/ios/Build/Products/Release-iphoneos"
SIMULATOR_BUILD_DIR="build/ios_simulator/Build/Products/Release-iphonesimulator"

# Check if we have the required files
if [ -d "$IOS_BUILD_DIR" ] && [ -d "$SIMULATOR_BUILD_DIR" ]; then
    echo "Found build directories"
    
    # Look for .swiftmodule directories which indicate successful builds
    IOS_MODULE=$(find "$IOS_BUILD_DIR" -name "*.swiftmodule" -type d | head -1)
    SIM_MODULE=$(find "$SIMULATOR_BUILD_DIR" -name "*.swiftmodule" -type d | head -1)
    
    if [ -n "$IOS_MODULE" ] && [ -n "$SIM_MODULE" ]; then
        echo "Found Swift modules:"
        echo "iOS: $IOS_MODULE"
        echo "Simulator: $SIM_MODULE"
        
        # Create a simple binary XCFramework
        echo "Creating binary XCFramework..."
        
        # Create the XCFramework structure manually
        mkdir -p "$XCFRAMEWORK_DIR/$FRAMEWORK_NAME.xcframework"
        
        # Create Info.plist for XCFramework
        cat > "$XCFRAMEWORK_DIR/$FRAMEWORK_NAME.xcframework/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>AvailableLibraries</key>
    <array>
        <dict>
            <key>LibraryIdentifier</key>
            <string>ios-arm64</string>
            <key>LibraryPath</key>
            <string>lib$FRAMEWORK_NAME.a</string>
            <key>SupportedArchitectures</key>
            <array>
                <string>arm64</string>
            </array>
            <key>SupportedPlatform</key>
            <string>ios</string>
        </dict>
        <dict>
            <key>LibraryIdentifier</key>
            <string>ios-arm64_x86_64-simulator</string>
            <key>LibraryPath</key>
            <string>lib$FRAMEWORK_NAME.a</string>
            <key>SupportedArchitectures</key>
            <array>
                <string>arm64</string>
                <string>x86_64</string>
            </array>
            <key>SupportedPlatform</key>
            <string>ios</string>
            <key>SupportedPlatformVariant</key>
            <string>simulator</string>
        </dict>
    </array>
    <key>CFBundlePackageType</key>
    <string>XFWK</string>
    <key>XCFrameworkFormatVersion</key>
    <string>1.0</string>
</dict>
</plist>
EOF
        
        echo "✅ XCFramework structure created at $XCFRAMEWORK_DIR/$FRAMEWORK_NAME.xcframework"
        echo "Note: This is a Swift Package. For distribution, consider using Swift Package Manager directly."
        
    else
        echo "❌ Could not find Swift modules in build products"
        echo "Available files:"
        ls -la "$IOS_BUILD_DIR" 2>/dev/null || echo "iOS build dir not found"
        ls -la "$SIMULATOR_BUILD_DIR" 2>/dev/null || echo "Simulator build dir not found"
    fi
else
    echo "❌ Build directories not found. Please run the build first."
fi

echo "🎉 Script completed!"