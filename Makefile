#
# Makefile for stackato-vcap-filesystem
#
# Used solely by packaging systems.
# Must support targets "all", "install", "uninstall".
#
# During the packaging install phase, the native packager will
# set either DESTDIR or prefix to the directory which serves as
# a root for collecting the package files.
#
# The resulting package installs in /home/stackato/stackato/vcap,
# is not intended to be relocatable.
#

NAME=stackato-vcap-filesystem

INSTALLROOT=/home/stackato/stackato/vcap
DIRNAME=$(INSTALLROOT)/filesystem

INSTDIR=$(DESTDIR)$(prefix)$(DIRNAME)

RSYNC_EXCLUDE=--exclude=.git --exclude=Makefile --exclude=.stackato-pkg --exclude=debian

all:
	@ true

install:
	mkdir -p $(INSTDIR)
	rsync -ap . $(INSTDIR) $(RSYNC_EXCLUDE)

uninstall:
	rm -rf $(INSTDIR)

clean:
	@ true
