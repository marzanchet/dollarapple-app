APP        := DollarApple
VERSION    ?= $(shell git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//')
ifeq ($(strip $(VERSION)),)
VERSION    := 0.0.0
endif
BUILD_NUM  ?= $(shell git rev-list --count HEAD 2>/dev/null)
ifeq ($(strip $(BUILD_NUM)),)
BUILD_NUM  := 1
endif
DIST       := dist
SIGN_IDENTITY ?= -

.PHONY: build build-store test app app-store run install zip clean icon strings

# SwiftPM never removes stale files from the resource bundle, so rebuild it from scratch.
build:
	rm -rf .build/release/DollarApple_DollarAppleUI.bundle
	swift build -c release --product $(APP)

build-store:
	rm -rf .build/release/DollarApple_DollarAppleUI.bundle
	swift build -c release --product $(APP)Store

test:
	swift test

## Direct build with Sparkle. Ad-hoc signed unless SIGN_IDENTITY is set.
app: build
	scripts/bundle.sh direct $(DIST) $(VERSION) $(BUILD_NUM)
	scripts/sign.sh $(DIST)/$(APP).app "$(SIGN_IDENTITY)"

## Mac App Store build: sandboxed, no Sparkle. Real signing needs the App Store certificates.
app-store: build-store
	scripts/bundle.sh store $(DIST)/store $(VERSION) $(BUILD_NUM)
	scripts/sign.sh $(DIST)/store/$(APP).app "$(SIGN_IDENTITY)" Packaging/$(APP)Store.entitlements

run: app
	pkill -x $(APP) || true
	open $(DIST)/$(APP).app

install: app
	pkill -x $(APP) || true
	rm -rf /Applications/$(APP).app
	cp -R $(DIST)/$(APP).app /Applications/$(APP).app
	open /Applications/$(APP).app

zip: app
	rm -f $(DIST)/$(APP)-$(VERSION).zip
	ditto -c -k --keepParent $(DIST)/$(APP).app $(DIST)/$(APP)-$(VERSION).zip
	shasum -a 256 $(DIST)/$(APP)-$(VERSION).zip

icon:
	swift Packaging/make-icon.swift Packaging/AppIcon.icns

## Regenerate .lproj files after editing Packaging/Localizable.xcstrings
strings:
	python3 scripts/gen-strings.py

clean:
	rm -rf .build $(DIST)
