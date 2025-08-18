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
	# 添加 -destination 'platform=iOS,device=*'
	xcodebuild -jobs 8 \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-sdk $(SDK) \
		-destination 'platform=iOS,device=*' \
		-derivedDataPath $(DERIVED_DATA_PATH) \
		CODE_SIGN_IDENTITY="" \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGNING_ALLOWED=NO \
		ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO \
		DSTROOT=$(INSTALL_DIR) \
		build  # 显式指定 action

	# 清理旧文件
	rm -rf ./build/MuffinStoreJailed.ipa
	rm -rf ./build/Payload
	mkdir -p ./build/Payload

	# 复制 App
	cp -rv ./build/Build/Products/Release-iphoneos/MuffinStoreJailed.app ./build/Payload

	# 打包 IPA
	cd ./build && zip -r MuffinStoreJailed.ipa Payload

	# 移动到根目录
	mv ./build/MuffinStoreJailed.ipa ./

clean:
	rm -rf ./build
	rm -rf ./MuffinStoreJailed.ipa
