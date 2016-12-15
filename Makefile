all : weeb

.PHONY : all deployable install deps-and-all

CFLAGS = "`pkg-config --cflags gtk+-3.0`"
LDFLAGS = "`pkg-config --libs gtk+-3.0`"

DESTDIR = /
PREFIX = /opt
INSTALL_DIR = $(DESTDIR)$(PREFIX)
BINDIR = $(DESTDIR)usr/bin/

weeb : weeb.scm gtk3_bindings.h
	csc -vk weeb.scm -C $(CFLAGS) -L $(LDFLAGS)

deploy_dir :
	mkdir -p deploy_dir

deploy_dir/weeb/weeb : weeb.scm gtk3_bindings.h
	mkdir -p deploy_dir/weeb
	csc -C $(CFLAGS) -L $(LDFLAGS) -deploy weeb.scm -o deploy_dir/weeb

# I'm checking for one of the *.so files, but it's really all the deps
deploy_dir/weeb/coops.so :
	mkdir -p deploy_dir/weeb
	chicken-install -deploy -p deploy_dir/weeb bind http-client uri-common openssl medea

deploy_dir/weeb/search.css : search.css
	cp search.css deploy_dir/weeb

deployable : deploy_dir/weeb/weeb deploy_dir/weeb/coops.so deploy_dir/weeb/search.css

install : deployable
	install -d $(INSTALL_DIR)
	install -d $(BINDIR)
	cp -r deploy_dir/* $(INSTALL_DIR)
	ln -s $(PREFIX)/weeb/weeb $(BINDIR)/weeb

deps-and-all :
	rm -rf prefix
	mkdir -p "prefix/lib/chicken/8/"
	unset CHICKEN_REPOSITORY
	chicken-install -init "prefix/lib/chicken/8"
	export CHICKEN_REPOSITORY="prefix/lib/chicken/8"
	chicken-install -p "prefix" bind http-client uri-common openssl medea
	$(MAKE) deployable
	rm deploy_dir/weeb/*.setup-info

