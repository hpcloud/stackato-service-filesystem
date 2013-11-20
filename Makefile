#
# Makefile for stackato-service-filesystem
#
# Used solely by packaging systems.
# Must support targets "all", "install", "uninstall".
#
# During the packaging install phase, the native packager will
# set either DESTDIR or prefix to the directory which serves as
# a root for collecting the package files.
#
# The resulting package installs in /s/code/services/filesystem,
# is not intended to be relocatable.
#

NAME=stackato-service-filesystem

INSTALLHOME=/home/stackato
INSTALLBASE=$(INSTALLHOME)/stackato
INSTALLROOT=$(INSTALLBASE)/code
DIRNAME=$(INSTALLROOT)/services/filesystem

HOMEDIR=$(DESTDIR)$(prefix)$(INSTALLHOME)
BASEDIR=$(DESTDIR)$(prefix)$(INSTALLBASE)
INSTDIR=$(DESTDIR)$(prefix)$(DIRNAME)

RSYNC_INCLUDE=--include=etc/filesystem
RSYNC_EXCLUDE=--exclude=/.git* --exclude=/Makefile --exclude=/.stackato-pkg --exclude=/debian --exclude=/etc/*

all:
	@ true

install:
	mkdir -p $(INSTDIR)
	rsync -ap . $(INSTDIR) $(RSYNC_INCLUDE) $(RSYNC_EXCLUDE)
	if [ -d etc ] ; then rsync -ap etc $(BASEDIR) --exclude=etc/filesystem ; fi
	chown -Rh stackato.stackato $(HOMEDIR)

uninstall:
	rm -rf $(INSTDIR)

clean:
	@ true

