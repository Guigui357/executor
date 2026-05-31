# File: NyxExecutor/NyxTweak/Makefile
TARGET = iphone:clang:latest:14.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = Roblox

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NyxExecutor
NyxExecutor_FILES = NyxExecutor.mm
NyxExecutor_CFLAGS = -fobjc-arc -std=c++17
NyxExecutor_LDFLAGS = -ldl

include $(THEOS_MAKE_PATH)/tweak.mk
 