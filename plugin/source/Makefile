# Makefile for SPS, made by moparisthebest modified by Wizzup
#
# Currently written for and tested to run only on Linux i386 and x86_64.
# Currently supports cross compilation to fpc targets i386-linux x86_64-linux i386-win32 x86_64-win64
# Obviously your system must have the needed binaries and libraries to cross-compile for that to work,
# but this will of course compile a native binary for your system only, if you wish.

.PHONY: default build rebuild unknown recursive_build clean i386-linux x86_64-linux i386-win32 x86_64-win64 all

# Set these
ifdef LAZARUS_PATH
lazaruspath := $(LAZARUS_PATH)
else
lazaruspath := /usr/lib/lazarus/0.9.28.2
endif

ifdef FPC_PATH
	fpcpath = $(FPC_PATH)
else
	fpcpath = fpc
endif

# Shouldn't need to touch below here, unless you add a unit or something...

# let's detect what linux platform we are running on, so if we run build or the default target
# we by default build the correct executable for our architecture...
# (cross-compiling is near-impossible on windows, so this makefile doesn't need to try and support it)
# as Simba supports more OSs (BSD, OSX etc) we can add support for cross compilation here too
uname_S := $(shell sh -c 'uname -s 2>/dev/null || echo not')
ifeq ($(uname_S),Linux)
	uname_M := $(shell sh -c 'uname -m 2>/dev/null || echo not')
	ifeq ($(uname_M),x86_64)
		our_target := x86_64-linux
	else ifeq ($(uname_M),i386)
		our_target := i386-linux
	else ifeq ($(uname_M),i486)
		our_target := i386-linux
	else ifeq ($(uname_M),i586)
		our_target := i386-linux
	else ifeq ($(uname_M),i686)
		our_target := i386-linux
	else
		our_target := unknown
	endif
else
	our_target := unknown
endif

CC := $(fpcpath)
build := $(CC)

# -Xd doesn't seem to cause problems when not cross-compiling, and is needed when cross-compiling, so I'm leaving it here
# -Xg = External debug file (Simba.dbg)
common_flags := -Xd -MObjFPC -Scgi -O2 -OoREGVAR -gl -vewnhi -l -Fu. -dLCL -Xg -fPIC
units := -FuSimba/Units/MMLCore -FuSimba/Units/Misc/DCPCrypt/ -FuSimba/Units/Linux/
includes := -FiSimba/Projects/Simba
#units := -Fu../../Units/MMLCore/ -Fu../../Units/MMLAddon/ -Fu../../Units/MMLAddon/PSInc/ -Fu../../Units/PascalScript/ -Fu../../Units/Misc/ -Fu../../Units/Linux/ -Fu../../Units/Synapse/ -Fu../../Units/RUTIS/ -Fu../../Units/lape -Fu../../Units/Misc/DCPCrypt -Fu../../Units/Misc/DCPCrypt/Ciphers -Fu../../Units/Misc/DCPCrypt/Hashes

binary := sps.$(platform)
# windows wants executables to end in .exe
ifeq ($(widgetset),win32)
	binary_extension := .dll
endif
ifeq ($(our_target),i386-linux)
	binary_extension := .so
endif
ifeq ($(our_target),x86_64-linux)
	binary_extension := .so
endif
lclplatpath := $(lazaruspath)/lcl/units/$(platform)/
lazarusunits := -Fu$(lazaruspath)/components/synedit/units/$(platform)/ -Fu$(lazaruspath)ideintf/units/$(platform)/ -Fu$(lclplatpath) -Fu$(lclplatpath)$(widgetset)/ -Fu$(lazaruspath)/packager/units/$(platform)/ -Fu$(lazaruspath)/components/mouseandkeyinput/ -Fu$(lazaruspath)/components/lazutils/

default: build

build: $(our_target)

rebuild: clean build

recursive_build: $(binary)$(binary_extension)

unknown:
	@echo Unable to auto-detect the OS and architecture you wish to build for, please specify target manually.

clean:
	rm *.so rm *.dll -f

$(binary)$(binary_extension):
	$(CC) $(common_flags) $(platform_flags) -dLCL$(widgetset) $(units) $(includes) $(lazarusunits) -o$(binary)$(binary_extension) sps.lpr
	strip $(binary)$(binary_extension)

i386-linux:
	$(MAKE) recursive_build platform="i386-linux" widgetset="gtk2" platform_flags="-Tlinux -Pi386 -dUseCThreads"
#	mv sps.dbg Simba.i386-linux.dbg

x86_64-linux:
	$(MAKE) recursive_build platform="x86_64-linux" widgetset="gtk2" platform_flags="-Tlinux -Px86_64 -dUseCThreads"
#	mv sps.dbg Simba.x86_64-linux.dbg

i386-win32:
	$(MAKE) recursive_build platform="i386-win32" widgetset="win32" platform_flags="-Twin32 -Pi386"
	# Windows already names the .dbg properly...

x86_64-win64:
	$(MAKE) recursive_build platform="x86_64-win64" widgetset="win32" platform_flags="-Twin64 -Px86_64"
	# Windows already names the .dbg properly...

all: i386-linux x86_64-linux i386-win32 x86_64-win64
