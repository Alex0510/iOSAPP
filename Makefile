BASEDIR = $(shell pwd)
BUILD_DIR = $(BASEDIR)/build
INSTALL_DIR = $(BUILD_DIR)/install
PROJECT = $(BASEDIR)/MuffinStoreJailed.xcodeproj
SCHEME = MuffinStoreJailed
CONFIGURATION = Release

all: ipa

ipa:
	mkdir -p ./build

	# 使用 iphoneos + 显式设置最低版本
	xcodebuild -jobs 8 \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-sdk iphoneos \
		-destination 'platform=iOS,device=*' \
		-derivedDataPath $(BUILD_DIR) \
		IPHONEOS_DEPLOYMENT_TARGET=15.0 \  # 支持 iOS 15+
		CODE_SIGN_IDENTITY="" \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGNING_ALLOWED=NO \
		ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO \
		DSTROOT=$(INSTALL_DIR) \
		build

	# 清理并打包 IPA
	rm -rf ./build/MuffinStoreJailed.ipa
	rm -rf ./build/Payload
	mkdir -p ./build/Payload
	cp -rv "./build/Build/Products/Release-iphoneos/MuffinStoreJailed.app" ./build/Payload
	cd ./build && zip -r MuffinStoreJailed.ipa Payload
	mv ./build/MuffinStoreJailed.ipa ./

clean:
	rm -rf ./build
	rm -rf ./MuffinStoreJailed.ipa
