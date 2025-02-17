swiftfiles := $(patsubst %.swift,bin/%,$(wildcard *.swift))
all: $(swiftfiles)

MONITOR_COMPILER_FLAGS = \
    -F$$PWD/Headers \
    -F/System/Library/PrivateFrameworks \
    -framework DisplayServices \
    -framework CoreDisplay \
    -framework OSD \
    -framework MonitorPanel \
    -import-objc-header Headers/Bridging-Header.h \
    lib/Extensions.swift

bin/SwapMonitors: SWIFTC_FLAGS=$(MONITOR_COMPILER_FLAGS)
bin/ToggleHDR: SWIFTC_FLAGS=$(MONITOR_COMPILER_FLAGS)
bin/RotateDisplay: SWIFTC_FLAGS=$(MONITOR_COMPILER_FLAGS)
bin/HorizontalMonitorLayout: SWIFTC_FLAGS=$(MONITOR_COMPILER_FLAGS)
bin/VerticalMonitorLayout: SWIFTC_FLAGS=$(MONITOR_COMPILER_FLAGS)
bin/MirrorMacBookToMonitor: SWIFTC_FLAGS=$(MONITOR_COMPILER_FLAGS)
bin/%: %.swift
	mkdir -p /tmp/$*
	cp -f $*.swift /tmp/$*/main.swift && \
	swiftc $(SWIFTC_FLAGS) -target arm64-apple-macos10.15.4 /tmp/$*/main.swift -o bin/$*-arm64 && \
	swiftc $(SWIFTC_FLAGS) -target x86_64-apple-macos10.15.4 /tmp/$*/main.swift -o bin/$*-x86 && \
	lipo -create -output bin/$* bin/$*-* && \
	rm /tmp/$*/main.swift

watch:
	rg -t swift --files | entr make -j$$(nproc)