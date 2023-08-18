all : weeb

.PHONY : all deployable install deps-and-all

CFLAGS = "`pkg-config --cflags gtk+-3.0`"
LDFLAGS = "`pkg-config --libs gtk+-3.0`"

PREFIX = /opt
INSTALL_DIR = $(DESTDIR)$(PREFIX)
BINDIR = $(DESTDIR)/usr/bin/

weeb : weeb.scm gtk3_bindings.h
	csc -vk weeb.scm -C $(CFLAGS) -L $(LDFLAGS)

deploy_dir/weeb/chicken.import.so :
	mkdir -p deploy_dir/weeb
	chicken-install -i deploy_dir/weeb

deploy_dir/weeb/weeb : weeb.scm gtk3_bindings.h deploy_dir/weeb/chicken.import.so
	csc -C $(CFLAGS) -L $(LDFLAGS) -deploy weeb.scm -o deploy_dir/weeb

# I'm checking for one of the *.so files, but it's really all the deps
deploy_dir/weeb/coops.so : deploy_dir/weeb/chicken.import.so
	mkdir -p deploy_dir/weeb
	chicken-install -deploy -p deploy_dir/weeb bind http-client uri-common openssl medea

deploy_dir/weeb/search.css : search.css
	mkdir -p deploy_dir/weeb
	cp search.css deploy_dir/weeb/

deployable : deploy_dir/weeb/weeb deploy_dir/weeb/coops.so deploy_dir/weeb/search.css

install : deployable
	install -d $(INSTALL_DIR)
	install -d $(BINDIR)
	cp -r deploy_dir/* $(INSTALL_DIR)
	ln -s $(PREFIX)/weeb/weeb $(BINDIR)/weeb


export CHICKEN_REPOSITORY_PATH := $(PWD)/prefix
export CHICKEN_INSTALL_REPOSITORY := $(PWD)/prefix
export CHICKEN_INSTALL_PREFIX := $(PWD)/prefix

deps-and-all :
	rm -rf prefix
	mkdir "prefix"
	cp /var/lib/chicken/11/* prefix/
	chicken-install bind http-client uri-common openssl medea
	$(MAKE) deployable
	rm deploy_dir/weeb/*.setup-info

