#                                                                         \
    This file is part of Giftray.                                         \
    Copyright 2020 cadeauthom <cadeauthom@gmail.com>                      \
                                                                          \
    Giftray is free software: you can redistribute it and/or modify       \
    it under the terms of the GNU General Public License as published by  \
    the Free Software Foundation, either version 3 of the License, or     \
    (at your option) any later version.                                   \
                                                                          \
    This program is distributed in the hope that it will be useful,       \
    but WITHOUT ANY WARRANTY; without even the implied warranty of        \
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         \
    GNU General Public License for more details.                          \
                                                                          \
    You should have received a copy of the GNU General Public License     \
    along with this program.  If not, see <https://www.gnu.org/licenses/>.\

AHKEXE = /mnt/c/Program\ Files/AutoHotkey/Compiler/Ahk2Exe.exe
AHKEXEFLAG = /mpress 0
AHKRUN = /mnt/c/Program\ Files/AutoHotkey/AutoHotkey.exe
AHKRUNFLAGS = /ErrorStdOut
#CONVERTIMG = /mnt/c/Program\ Files/ImageMagick-7.0.8-Q16/magick.exe
CONVERTIMG = /usr/bin/convert
CONVERTIMGFLAGS = -background none -define icon:auto-resize=32 svg:-
#COMPRESS = /mnt/c/Program\ Files/AutoHotkey/Compiler/mpress.exe
#COMPRESS = ./upx-3.95-win64/upx.exe
COMPRESS = /usr/bin/upx
COMPRESSFLAGS = --ultra-brute --compress-icons=0

PROJECT = giftray
default_color = blue

BUILDDIR = ./build
INSTALLDIR = ./install
SRCDIR = ./src
SVGDIR = ./svg
CONFDIR = ./conf
ICOPATH = icons
ICONSDIR = $(BUILDDIR)/$(ICOPATH)

SRCS = $(SRCDIR)/$(PROJECT).ahk
LIBS = $(wildcard  $(SRCDIR)/lib/*.ahk)
EXEC = $(BUILDDIR)/$(PROJECT).exe

AHKINSTALL = $(BUILDDIR)/setup_$(PROJECT).ahk
INSTALL_SRC = $(SRCDIR)/set.ahk
INSTALL_AHK = $(BUILDDIR)/set.ahk
INSTALL_BUILDER = $(SRCDIR)/setup.ahk
INSTALL_LIB = $(BUILDDIR)/lib/setup_built.ahk
SETUP = $(INSTALLDIR)/setup_$(PROJECT).exe

ICO = $(ICONSDIR)/$(default_color)/$(PROJECT)-0.ico
SVG = $(wildcard $(SVGDIR)/*.svg)
ICOS_BLUE   =   $(patsubst $(SVGDIR)/%.svg, $(ICONSDIR)/blue/%.ico, $(SVG))
ICOS_BLACK  =   $(patsubst $(SVGDIR)/%.svg, $(ICONSDIR)/black/%.ico,$(SVG))
ICOS_RED    =   $(patsubst $(SVGDIR)/%.svg, $(ICONSDIR)/red/%.ico,  $(SVG))
ICOS_GREEN  =   $(patsubst $(SVGDIR)/%.svg, $(ICONSDIR)/green/%.ico,$(SVG))

CONFSRC = $(wildcard $(CONFDIR)/*.conf)
CONF = $(patsubst $(CONFDIR)/%, $(BUILDDIR)/%, $(CONFSRC))
CSVSRC = $(wildcard $(CONFDIR)/*.csv)
CSV = $(patsubst $(CONFDIR)/%, $(BUILDDIR)/%, $(CSVSRC))
DOCSRC = README.md
DOC = $(BUILDDIR)/README.md

PRECOMPIL = $(SRCDIR)/compil.ahk

all: exec conf ico doc

compil: $(SETUP)

exec: $(EXEC)

conf: $(CONF) $(CSV)

ico: $(ICOS_BLUE) $(ICOS_BLACK) $(ICOS_RED) $(ICOS_GREEN)

doc: $(DOC)

$(INSTALL_AHK): $(INSTALL_SRC)
	mkdir -p $(@D)
	cp $< $@
	
$(INSTALL_LIB): $(INSTALL_BUILDER)
	mkdir -p $(@D)
	$(AHKRUN) $(AHKRUNFLAGS) $< $(PROJECT) $@

$(SETUP): $(INSTALL_AHK) $(INSTALL_LIB) all
	mkdir -p $(@D)
	$(AHKEXE) $(AHKEXEFLAG) /in $< /icon $(ICO) /out $@
	if [ -f $(COMPRESS) ]; then $(COMPRESS) $(COMPRESSFLAGS) $@; fi;

$(EXEC): $(SRCS) $(LIBS) $(ICO)
	mkdir -p $(@D)
	@echo "global_var.buildinfo.branch := \"$$(git rev-parse --abbrev-ref HEAD)\"" > $(PRECOMPIL)
	@echo "global_var.buildinfo.commit := \"$$(git log -1 --pretty=format:'%h')\"" >> $(PRECOMPIL)
	@echo "global_var.buildinfo.modif  := \"$$(git status --porcelain -uno | wc -l)\""  >> $(PRECOMPIL)
	@echo "global_var.buildinfo.date   := \"$$(date '+%Y%m%d%H%M%S')\""   >> $(PRECOMPIL)
	@echo "global_var.buildinfo.tag    := \"$$(git describe --exact-match --tags $(git log -n1 --pretty='%h'))\""   >> $(PRECOMPIL)
	@echo "global_var.icoPath          := \"$(ICOPATH)\\\\$(default_color)\\\""   >> $(PRECOMPIL)
	$(AHKEXE) $(AHKEXEFLAG) /in $< /icon $(ICO) /out $@
	mv $(PRECOMPIL) $(BUILDDIR)/
	if [ -f $(COMPRESS) ]; then $(COMPRESS) $(COMPRESSFLAGS) $@; fi;

$(CONF): $(CONFSRC)
	mkdir -p $(@D)
	cp $< $@

$(CSV): $(CSVSRC)
	mkdir -p $(@D)
	cp $< $@

$(DOC): $(DOCSRC)
	mkdir -p $(@D)
	cp $< $@

$(ICONSDIR)/blue/%.ico: $(SVGDIR)/%.svg
	mkdir -p $(@D)
	cat $< \
        | $(CONVERTIMG) $(CONVERTIMGFLAGS)  $@

$(ICONSDIR)/black/%.ico: $(SVGDIR)/%.svg
	mkdir -p $(@D)
	sed -e s/1185E0/5a5a5a/g -e s/4DCFE0/aaaaaa/g $< \
        | $(CONVERTIMG) $(CONVERTIMGFLAGS) $@

$(ICONSDIR)/red/%.ico: $(SVGDIR)/%.svg
	mkdir -p $(@D)
	sed -e s/1185E0/ED664C/g -e s/4DCFE0/FDC75B/g $< \
        | $(CONVERTIMG) $(CONVERTIMGFLAGS) $@

$(ICONSDIR)/green/%.ico: $(SVGDIR)/%.svg
	mkdir -p $(@D)
	sed -e s/1185E0/32CD32/g -e s/4DCFE0/7CFC00/g $< \
        | $(CONVERTIMG) $(CONVERTIMGFLAGS) $@

mrproper: clean
	rm -f $(SETUP)

cleanexe:
	rm -rf $(BUILDDIR)/*.exe
	rm -rf $(BUILDDIR)/*.ahk

clean: cleanexe
	rm -rf $(BUILDDIR)/*.conf
	rm -rf $(BUILDDIR)/*.csv
	rm -rf $(BUILDDIR)/*.md
	rm -rf $(ICONSDIR)/*/*.ico
