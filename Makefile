# Makefile for 2dx
#
export prefix=/usr/local/2dx
export eprefix=${prefix}
export bindir=${eprefix}/bin
export sbindir=${eprefix}/sbin
export libexecdir=${eprefix}/libexec
export datadir=${prefix}/share
export sysconfdir=${prefix}/etc
export sharedstatedir=${prefix}/com
export localstatedir=${prefix}/var
export libdir=${eprefix}/lib
export includedir=${prefix}/include
export oldincludedir=/usr/include
export infodir=${prefix}/info
export mandir=${prefix}/man

SUBDIRS = ./lib/src  ./lib/src/conf ./lib/src/widgets ./lib/src/mrcImage ./lib/src/extentions ./2dx_image ./2dx_merge ./2dx_logbrowser  ./kernel
INSTALL = /opt/local/bin/ginstall -c
COPY = cp -r
FILE_EXISTS = test -e
DIR_EXISTS = test -d
LINK = ln -sf
RM = rm -rf

all: $(SUBDIRS:=/all.target)

clean: $(SUBDIRS:=/clean.target)

install:
	#Installing to $(root)$(prefix)
	@$(INSTALL) -d \
	    $(root)$(prefix)/2dx_image/resource \
	    $(root)$(prefix)/2dx_merge/resource \
	    $(root)$(prefix)/2dx_logbrowser/resource \
	    $(root)$(prefix)/plugins/translators \
	    $(root)$(prefix)/bin

	@$(INSTALL) ./LICENSE $(root)$(prefix)
	@$(INSTALL) ./INSTALL.SOURCE $(root)$(prefix)

	@$(INSTALL) plugins/translators/*.tr $(root)$(prefix)/plugins/translators/


	@if $(FILE_EXISTS) "./2dx_image/2dx_image"; then $(INSTALL) -s 2dx_image/2dx_image $(root)$(prefix)/2dx_image/; $(INSTALL) ./bin/2dx_image.linux $(root)$(prefix)/bin/2dx_image; $(INSTALL) ./bin/2dx_logbrowser.linux $(root)$(prefix)/bin/2dx_logbrowser; fi
	@if $(DIR_EXISTS) "./2dx_image/2dx_image.app"; then $(COPY) 2dx_image/2dx_image.app $(root)$(prefix)/2dx_image/; $(INSTALL) ./bin/2dx_image.mac $(root)$(prefix)/bin/2dx_image; $(LINK) $(root)$(prefix)/2dx_image/2dx_image.app $(root)$(prefix)/bin/2dx_image.app; fi

	@if $(FILE_EXISTS) "./2dx_merge/2dx_merge"; then $(INSTALL) -s 2dx_merge/2dx_merge $(root)$(prefix)/2dx_merge/; $(INSTALL) ./bin/2dx_merge.linux $(root)$(prefix)/bin/2dx_merge; fi
	@if $(DIR_EXISTS) "./2dx_merge/2dx_merge.app"; then $(COPY) 2dx_merge/2dx_merge.app $(root)$(prefix)/2dx_merge/; $(INSTALL) ./bin/2dx_merge.mac $(root)$(prefix)/bin/2dx_merge; $(LINK) $(root)$(prefix)/2dx_merge/2dx_merge.app $(root)$(prefix)/bin/2dx_merge.app; fi

	@if $(FILE_EXISTS) "./2dx_logbrowser/2dx_logbrowser"; then $(INSTALL) -s 2dx_logbrowser/2dx_logbrowser $(root)$(prefix)/2dx_logbrowser/; $(INSTALL) ./bin/2dx_logbrowser.linux $(root)$(prefix)/bin/2dx_logbrowser; fi
	@if $(DIR_EXISTS) "./2dx_logbrowser/2dx_logbrowser.app"; then $(COPY) 2dx_logbrowser/2dx_logbrowser.app $(root)$(prefix)/2dx_logbrowser/; $(INSTALL) ./bin/2dx_logbrowser.mac $(root)$(prefix)/bin/2dx_logbrowser; $(LINK) $(root)$(prefix)/2dx_logbrowser/2dx_logbrowser.app $(root)$(prefix)/bin/2dx_logbrowser.app; fi
   
	  @$(INSTALL) 2dx_image/resource/*.png $(root)$(prefix)/2dx_image/resource
	  @$(INSTALL) 2dx_merge/resource/*.png $(root)$(prefix)/2dx_merge/resource
	  @$(INSTALL) 2dx_logbrowser/resource/*.png $(root)$(prefix)/2dx_logbrowser/resource


	@$(MAKE) $(MFLAGS) -C kernel install prefix=$(root)$(prefix)/kernel

	@cd $(root)$(prefix); $(LINK) kernel/proc ./proc; $(LINK) kernel/config ./config
	@cd $(root)$(prefix)/2dx_image/; $(LINK) ../kernel/mrc/bin ./bin; $(LINK) ../kernel/2dx_image/scripts-standard ./scripts-standard; $(LINK) ../kernel/2dx_image/scripts-custom ./scripts-custom;
	@cd $(root)$(prefix)/2dx_merge/; $(LINK) ../kernel/mrc/bin ./bin; $(LINK) ../kernel/2dx_merge/scripts-standard ./scripts-standard; $(LINK) ../kernel/2dx_merge/scripts-custom ./scripts-custom;

uninstall:
	@$(RM) $(root)$(prefix)


%.target:
	@echo $(MAKE) $(MFLAGS) -C $(*D) $(*F)
	@[ -d $(*D) ] && $(MAKE) $(MFLAGS) -C $(*D) $(*F)
