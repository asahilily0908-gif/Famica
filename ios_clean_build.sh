#!/bin/bash

# iOS Clean Build Script for Archive Fix
# Run this before attempting Xcode Archive

set -e  # Exit on error

echo "================================================"
echo "iOS Clean Build Script - Starting"
echo "================================================"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

cd "$(dirname "$0")"
PROJECT_ROOT=$(pwd)

echo ""
echo "${BLUE}STEP 1: Flutter Clean${NC}"
flutter clean
echo "${GREEN}✓ Flutter clean completed${NC}"

echo ""
echo "${BLUE}STEP 2: Remove iOS Build Artifacts${NC}"
rm -rf ios/Pods
rm -rf ios/Podfile.lock
rm -rf ios/.symlinks
rm -rf ios/Flutter/Flutter.framework
rm -rf ios/Flutter/Flutter.podspec
echo "${GREEN}✓ iOS artifacts removed${NC}"

echo ""
echo "${BLUE}STEP 3: Remove Xcode DerivedData${NC}"
rm -rf ~/Library/Developer/Xcode/DerivedData/*
echo "${GREEN}✓ DerivedData cleared${NC}"

echo ""
echo "${BLUE}STEP 4: Clean CocoaPods Cache${NC}"
pod cache clean --all
echo "${GREEN}✓ CocoaPods cache cleared${NC}"

echo ""
echo "${BLUE}STEP 5: Flutter Pub Get${NC}"
flutter pub get
echo "${GREEN}✓ Dependencies fetched${NC}"

echo ""
echo "${BLUE}STEP 6: Pod Install${NC}"
cd ios
pod install --repo-update
cd ..
echo "${GREEN}✓ Pods installed${NC}"

echo ""
echo "${BLUE}STEP 7: Build iOS Release (Test)${NC}"
flutter build ios --release --no-codesign
echo "${GREEN}✓ Release build successful${NC}"

echo ""
echo "================================================"
echo "${GREEN}✓ Clean Build Completed Successfully!${NC}"
echo "================================================"
echo ""
echo "Next steps:"
echo "1. Open Xcode: ${BLUE}open ios/Runner.xcworkspace${NC}"
echo "2. Select 'Any iOS Device (arm64)' as target"
echo "3. Menu: Product → Archive"
echo "4. Wait for build to complete"
echo ""
echo "If Archive fails, check IOS_ARCHIVE_FIX_GUIDE.md"
echo "================================================"
