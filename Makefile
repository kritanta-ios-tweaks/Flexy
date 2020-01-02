#Makefile based off of NSExceptional's: https://github.com/NSExceptional/FLEXing/blob/master/Makefile


#change the target, but you might lose NSLog in console
export TARGET = iphone:11.2:11.0
include $(THEOS)/makefiles/common.mk
ARCHS = arm64 arm64e
TWEAK_NAME = Flexy

# FULL PATH of the FLEX repo on your own machine
FLEX_ROOT = ./

# Function to convert /foo/bar to -I/foo/bar
dtoim = $(foreach d,$(1),-I$(d))

# Gather FLEX sources
SOURCES = $(shell find $(FLEX_ROOT)/Classes -name '*.m')
# Gather FLEX headers for search paths
_IMPORTS =  $(shell /bin/ls -d $(FLEX_ROOT)/Classes/*/)
_IMPORTS += $(shell /bin/ls -d $(FLEX_ROOT)/Classes/*/*/)
IMPORTS = -I$(FLEX_ROOT)/Classes/ $(call dtoim, $(_IMPORTS))

Flexy_FRAMEWORKS = CoreGraphics UIKit ImageIO QuartzCore
Flexy_FILES = Flexy.xm $(SOURCES)
Flexy_LIBRARIES = sqlite3 z
Flexy_CFLAGS += -fobjc-arc -w $(IMPORTS)

include $(THEOS_MAKE_PATH)/tweak.mk


after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += flexyprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
