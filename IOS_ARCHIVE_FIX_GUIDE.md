# iOS Archive Build Fix Guide

## Problem
- Debug build works (`flutter run`)
- Release/Archive fails with errors:
  - `'Flutter/Flutter.h' file not found`
  - `could not build module 'share_plus'`

## Root Cause
1. CocoaPods cache corruption
2. Missing `use_modular_headers!` for Firebase/gRPC
3. Build artifacts from Debug interfering with Release

---

## STEP 1: Complete Clean

Execute these commands in order:

```bash
# Navigate to project root
cd /Users/matsushimaasahi/Developer/famica

# 1. Clean Flutter
flutter clean

# 2. Remove iOS build artifacts
rm -rf ios/Pods
rm -rf ios/Podfile.lock
rm -rf ios/.symlinks
rm -rf ios/Flutter/Flutter.framework
rm -rf ios/Flutter/Flutter.podspec

# 3. Remove derived data (ALL Xcode caches)
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# 4. Remove CocoaPods cache
pod cache clean --all

# 5. Get Flutter dependencies
flutter pub get
```

---

## STEP 2: Fix Podfile

The current Podfile is missing `use_modular_headers!` which is critical for Firebase + gRPC.

Current Podfile location: `ios/Podfile`

**Required change:** Add `use_modular_headers!` after `use_frameworks!`

---

## STEP 3: Reinstall Pods

```bash
# Navigate to ios directory
cd ios

# Install pods with repo update
pod install --repo-update

# Go back to project root
cd ..
```

---

## STEP 4: Build Release from Command Line

```bash
# Build iOS release (this will catch errors early)
flutter build ios --release --no-codesign
```

**Expected:** This should complete without errors.  
**If errors occur:** They will be shown here before attempting Xcode Archive.

---

## STEP 5: Xcode Archive

1. **Open WORKSPACE (not .xcodeproj)**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Verify Target Settings** (in Xcode):
   - Select `Runner` target
   - Build Settings → Search "ENABLE_BITCODE"
   - Set to: **No** (Bitcode deprecated in Xcode 14+)

3. **Verify Signing**:
   - Signing & Capabilities tab
   - Team: Select your Apple Developer Team
   - Signing Certificate: Apple Distribution

4. **Archive**:
   - Menu: Product → Archive
   - Wait for build to complete

---

## STEP 6: Verification Checklist

After completing all steps, verify:

- [ ] `flutter clean` executed successfully
- [ ] All `ios/Pods` and caches removed
- [ ] Podfile updated with `use_modular_headers!`
- [ ] `pod install` completed without errors
- [ ] `flutter build ios --release --no-codesign` succeeded
- [ ] Opened `Runner.xcworkspace` (not .xcodeproj)
- [ ] ENABLE_BITCODE set to No
- [ ] Archive completed successfully
- [ ] Archive appears in Xcode Organizer

---

## Common Errors & Solutions

### Error: "Flutter/Flutter.h file not found"
**Cause:** Flutter framework not properly linked  
**Solution:** Ensure you opened `.xcworkspace` and ran `flutter pub get` + `pod install`

### Error: "could not build module 'share_plus'"
**Cause:** Missing modular headers  
**Solution:** Add `use_modular_headers!` to Podfile

### Error: "Code signing required"
**Cause:** No provisioning profile  
**Solution:** Select development team in Signing & Capabilities

### Error: "Build input file cannot be found"
**Cause:** Stale DerivedData  
**Solution:** Delete DerivedData and clean build folders

---

## Next Steps After Successful Archive

1. In Xcode Organizer, select the archive
2. Click "Distribute App"
3. Choose "App Store Connect"
4. Follow upload wizard
5. Check App Store Connect for uploaded build (takes 5-10 minutes)

---

## Emergency Fallback

If all else fails:

```bash
# Nuclear option: Remove everything and start fresh
cd /Users/matsushimaasahi/Developer/famica
flutter clean
rm -rf ios/Pods ios/Podfile.lock ios/.symlinks
rm -rf ~/Library/Developer/Xcode/DerivedData/*
flutter pub get
cd ios
pod deintegrate
pod install --repo-update
cd ..
flutter build ios --release --no-codesign
```

Then try Archive again in Xcode.
