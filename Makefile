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
	# ✅ 添加 -destination 'generic/platform=iOS' 解决 CI 构建失败
	xcodebuild -jobs 8 \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-sdk $(SDK) \
		-destination 'generic/platform=iOS' \
		-derivedDataPath $(DERIVED_DATA_PATH) \
		CODE_SIGN_IDENTITY="" \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGNING_ALLOWED=NO \
		ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO \
		DSTROOT=$(INSTALL_DIR) \
		clean build
	# 清理旧文件
	rm -rf ./build/MuffinStoreJailed.ipa
	rm -rf ./build/Payload
	# 打包 IPA
	mkdir -p ./build/Payload
	cp -rv ./build/Build/Products/Release-iphoneos/MuffinStoreJailed.app ./build/Payload
	cd ./build && zip -r MuffinStoreJailed.ipa Payload
	mv ./build/MuffinStoreJailed.ipa ./

clean:
	rm -rf ./build
	rm -rf ./MuffinStoreJailed.ipa
