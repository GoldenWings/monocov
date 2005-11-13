
PROJECTNAME = monocov
GUI = gtk
MONO_ROOT = ../mono

all: monocov.exe libmono-profiler-monocov.so symbols.exe

ifeq ($(GUI), gtk)
GUI_SRCS = \
	gui/gtk/MonoCov.cs \
	gui/gtk/CoverageView.cs \
	gui/gtk/SourceWindow.cs
GUI_LIBS = -pkg:gtk-sharp -pkg:gnome-sharp -pkg:glade-sharp -r:System.Drawing -resource:gui/gtk/monocov.glade,monocov.glade
else
GUI_SRCS = \
	gui/qt/MonoCov.cs \
	gui/qt/CoverageView.cs \
	gui/qt/SourceWindow.cs \
	gui/qt/FilterDialog.cs 
GUI_LIBS = -r Qt
endif

SRCS = \
	CoverageItem.cs \
	NamespaceCoverageItem.cs \
	ClassCoverageItem.cs \
	MethodCoverageItem.cs \
	CoverageModel.cs \
	SourceFileCoverageData.cs \
	XmlExporter.cs \
	HtmlExporter.cs \
	MonoCovMain.cs \
	$(GUI_SRCS)

monocov.exe: $(SRCS) style.xsl .gui-$(GUI)
	mcs -debug /target:exe /out:$@ -define:GUI_$(GUI) -r:Mono.CompilerServices.SymbolWriter -r:Mono.GetOptions $(GUI_LIBS) $(SRCS) -resource:style.xsl,style.xsl -resource:trans.gif,trans.gif

.gui-gtk:
	@rm -f .gui-*
	@touch .gui-gtk

.gui-qt:
	@rm -f .gui-*
	@touch .gui-qt

symbols.exe: symbols.cs
	mcs -debug /target:exe /out:$@ -r:Mono.CompilerServices.SymbolWriter symbols.cs

nunit-console.exe: nunit-console.cs
	mcs -r:nunit.framework -r:nunit.core -r:nunit.util -r:Mono.GetOptions nunit-console.cs

libmono-profiler-monocov.so: coverage.c
	$(CC) -g -I$(MONO_ROOT) `pkg-config --cflags glib-2.0` --shared -fPIC -o $@ $^

test:
	mcs -g test.cs
	mono --profile=monocov:outfile=res.cov test.exe

cortests:
	MONO_PATH=../mcs/class/corlib mono --profile=monocov:outfile=corlib-tests.cov,+[mscorlib] nunit-console.exe corlib_test.dll

xml-cortests:
	mono ./monocov.exe --export-xml=export corlib-tests.cov
	tar cvzf corlib-tests.tar.gz export

html-cortests:
	mono ./monocov.exe --export-html=html-export corlib-tests.cov
	tar cvzf html-tests.tar.gz html-export

emittests:
	MONO_PATH=../mcs/class/corlib/Test mono --profile=monocov:outfile=emittests.cov,+[corlib]System.Reflection.Emit nunit-console.exe corlib_test.dll Reflection.Emit

hash-test:
	mono --profile=monocov:+Hashtable hash-table.exe

test-colorizer.exe: test-colorizer.cs SyntaxHighlighter.cs
	mcs -g /out:$@ $^

clean:
	rm -f monocov.exe symbols.exe nunit-console.exe libmono-profiler-monocov.so

distrib:
	tar -cvhzf $(PROJECTNAME).tar.gz `cat MANIFEST` && DIRNAME=$(PROJECTNAME)-`date +%d-%b-%y` && rm -rf $$DIRNAME && mkdir $$DIRNAME && mv $(PROJECTNAME).tar.gz $$DIRNAME && cd $$DIRNAME && tar -xzf $(PROJECTNAME).tar.gz && rm $(PROJECTNAME).tar.gz && cd - && tar -cvzf $$DIRNAME.tar.gz $$DIRNAME && rm -rf $$DIRNAME
