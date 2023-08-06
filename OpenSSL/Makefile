##
# Makefile for OpenSSL
##

# Project info
Project         = openssl
ProjectName     = OpenSSL
UserType        = Developer
ToolType        = Libraries
Configure       = $(Sources)/Configure
Extra_CC_Flags  = -Wno-precomp -DTIMES -DNO_GMTIME_R -DUSE_TOD

include $(MAKEFILEPATH)/CoreOS/ReleaseControl/GNUSource.make

Configure_Flags = nextstep --prefix="$(DSTROOT)/usr"

Environment     = CFLAG="$(CFLAGS)"									\
		  AR="$(SRCROOT)/ar.sh r"								\
		  PERL='/usr/bin/perl'									\
		  BINDIR="$(USRDIR)/bin"
				\
		  LIBDIR=$(USRDIR)/lib"
				\
		  INCLUDEDIR="$(USRDIR)/include/openssl"						\
		  MANDIR="$(MANDIR)"

Install_Target  = install

# Shadow the source tree
lazy_install_source:: shadow_source
	$(_v) if [ -L $(BuildDirectory)/Makefile.ssl ]; then						\
		 $(RM) "$(BuildDirectory)/Makefile.ssl";						\
		 $(CP) "$(Sources)/Makefile.ssl" "$(BuildDirectory)/Makefile.ssl";			\
		 $(RM) "$(BuildDirectory)/crypto/opensslconf.h";					\
		 $(CP) "$(Sources)/crypto/opensslconf.h" "$(BuildDirectory)/crypto/opensslconf.h";	\
	      fi

test:: build
	$(MAKE) -C "$(BuildDirectory)" test