include $(THEOS)/makefiles/common.mk
ARCHS = arm64 arm64e
BUNDLE_NAME = Flexyprefs
Flexyprefs_FILES = $(wildcard *.m)
Flexyprefs_INSTALL_PATH = /Library/PreferenceBundles
Flexyprefs_FRAMEWORKS = UIKit
Flexyprefs_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/Flexyprefs.plist$(ECHO_END)
