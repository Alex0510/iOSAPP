mkdir -p ./build

xcodebuild \
    -project "/Users/runner/work/MuffinStoreJailed_iOS/MuffinStoreJailed_iOS/MuffinStoreJailed.xcodeproj" \
    -scheme MuffinStoreJailed \
    -configuration Release \
    -sdk iphoneos \
    -destination 'generic/platform=iOS' \
    -derivedDataPath "./build" \
    SDKROOT=iphoneos18.0 \
    IPHONEOS_DEPLOYMENT_TARGET=15.0 \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO \
    DSTROOT="./build/install" \
    clean build \
    | tee build.log

# 打包成 .ipa
xcrun --sdk iphoneos PackageApplication \
    -v "./build/Build/Products/Release-iphoneos/MuffinStoreJailed.app" \
    -o "./build/MuffinStoreJailed.ipa"
