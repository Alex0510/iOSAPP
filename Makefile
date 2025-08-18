BASEDIR = $(shell pwd)
BUILD_DIR = $(BASEDIR)/build
INSTALL_DIR = $(BUILD_DIR)/install
PROJECT = $(BASEDIR)/MuffinStoreJailed.xcodeproj
SCHEME = MuffinStoreJailed
CONFIGURATION = Release
SDK = iphoneos
DERIVED_DATA_PATH = $(BUILD_DIR)

all: ipa

ipa:
	mkdir -p ./build
	# SDKROOT=iphoneos15.0 强制使用已安装的 SDK
	xcodebuild -jobs 8 \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-sdk $(SDK) \
		-derivedDataPath $(DERIVED_DATA_PATH) \
		SDKROOT=iphoneos17.5 \
		IPHONEOS_DEPLOYMENT_TARGET=15.0 \
		CODE_SIGN_IDENTITY="" \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGNING_ALLOWED=NO \
		ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO \
		DSTROOT=$(INSTALL_DIR)

	# 打包 IPA
	rm -rf ./build/MuffinStoreJailed.ipa
	rm -rf ./build/Payload
	mkdir -p ./build/Payload
	cp -rv "./build/Build/Products/Release-iphoneos/MuffinStoreJailed.app" ./build/Payload
	cd ./build && zip -r MuffinStoreJailed.ipa Payload
	mv ./build/MuffinStoreJailed.ipa ./

clean:
	rm -rf ./build
	rm -rf ./MuffinStoreJailed.ipa
