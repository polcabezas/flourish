XCODEGEN    := xcodegen
XCODEPROJ   := Flourish.xcodeproj
WORKSPACE   := $(XCODEPROJ)/project.xcworkspace
SHARED_DATA := $(WORKSPACE)/xcshareddata
SETTINGS    := $(SHARED_DATA)/WorkspaceSettings.xcsettings

.PHONY: generate open clean

# Generate the .xcodeproj and immediately pin DerivedData to the project folder.
# Always run this instead of calling xcodegen directly.
generate:
	$(XCODEGEN) generate
	mkdir -p $(SHARED_DATA)
	@printf '%s\n' \
	  '<?xml version="1.0" encoding="UTF-8"?>' \
	  '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' \
	  '<plist version="1.0">' \
	  '<dict>' \
	  '	<key>DerivedDataLocationStyle</key>' \
	  '	<string>WorkspaceRelativePath</string>' \
	  '	<key>DerivedDataCustomLocation</key>' \
	  '	<string>build/DerivedData</string>' \
	  '</dict>' \
	  '</plist>' \
	  > $(SETTINGS)
	@echo "✓ DerivedData pinned to ./build/DerivedData"

# Generate and open in Xcode
open: generate
	open $(XCODEPROJ)

# Remove generated artefacts (does not touch source files)
clean:
	rm -rf $(XCODEPROJ) build/
