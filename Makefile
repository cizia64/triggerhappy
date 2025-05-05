# Cross toolchain
CROSS_COMPILE := /opt/aarch64-linux-gnu-7.5.0-linaro/bin/aarch64-linux-gnu-
SYSROOT := /opt/aarch64-linux-gnu-7.5.0-linaro/sysroot

# Compiler
CC := $(CROSS_COMPILE)gcc --sysroot=$(SYSROOT)
PKGCONFIG := $(CROSS_COMPILE)pkg-config

# Paths to libs (optionnel si pkg-config marche)
INCLUDES :=
LIBS :=

# Static build flags
#CFLAGS := -O2 -static $(INCLUDES)
#CPPFLAGS :=
#LDFLAGS := -static $(LIBS)

# Install dirs
PREFIX := /usr
DESTDIR := $(SYSROOT)
BINDIR := $(DESTDIR)$(PREFIX)/sbin
MANDIR := $(DESTDIR)$(PREFIX)/share/man/man1

# Version
VERSION := $(shell cat version.inc)

# Libsystemd
HAVE_PKGCONFIG := $(shell $(PKGCONFIG) --version 2>/dev/null || echo no)
ifeq ($(HAVE_PKGCONFIG),no)
	HAVE_SYSTEMD := 0
else
	HAVE_SYSTEMD := $(shell PKG_CONFIG_SYSROOT_DIR=$(SYSROOT) PKG_CONFIG_LIBDIR=$(SYSROOT)/usr/lib/pkgconfig:$(SYSROOT)/usr/share/pkgconfig $(PKGCONFIG) --exists libsystemd && echo 1 || echo 0)
	ifeq ($(HAVE_SYSTEMD),1)
		CPPFLAGS += -DHAVE_SYSTEMD=1
		CFLAGS += $(shell PKG_CONFIG_SYSROOT_DIR=$(SYSROOT) PKG_CONFIG_LIBDIR=$(SYSROOT)/usr/lib/pkgconfig:$(SYSROOT)/usr/share/pkgconfig $(PKGCONFIG) --cflags libsystemd)
		LDLIBS += $(shell PKG_CONFIG_SYSROOT_DIR=$(SYSROOT) PKG_CONFIG_LIBDIR=$(SYSROOT)/usr/lib/pkgconfig:$(SYSROOT)/usr/share/pkgconfig $(PKGCONFIG) --libs libsystemd)
	endif
endif

# Composants
THD_COMPS := thd keystate trigger eventnames devices cmdsocket obey ignore uinput triggerparser
THCMD_COMPS := th-cmd cmdsocket

MAKEDEPEND = $(CC) -M -MG $(CPPFLAGS) -o $*.d $<

all: thd th-cmd man

man: thd.1 th-cmd.1

thd: $(THD_COMPS:%=%.o)

th-cmd: $(THCMD_COMPS:%=%.o)

%.1: %.pod
	pod2man \
		--center="Triggerhappy daemon" \
		--section=1 \
		--release="$(VERSION)" \
		$< > $@

linux_input_defs_gen.inc:
	echo "#include <linux/input.h>" | $(CC) $(CPPFLAGS) -dM -E - > $@

evtable_%.inc: linux_input_defs_gen.inc
	awk '/^#define $*_/ && $$2 !~ /_(MIN_INTERESTING|MAX|CNT|VERSION)$$/ {print "EV_MAP("$$2"),"}' $< > $@

version.h: version.inc
	sed -r 's!(.*)!#define TH_VERSION "\1"!' $< > $@

clean:
	rm -f *.d *.o
	rm -f linux_input_defs_gen.inc evtable_*.inc version.h
	rm -f thd th-cmd thd.1 th-cmd.1

install: all
	install -D thd $(BINDIR)/thd
	install -D th-cmd $(BINDIR)/th-cmd
	install -D thd.1 $(MANDIR)/thd.1
	install -D th-cmd.1 $(MANDIR)/th-cmd.1

%.d : %.c
	$(MAKEDEPEND)

-include $(THD_COMPS:%=%.d) $(THCMD_COMPS:%=%.d)
