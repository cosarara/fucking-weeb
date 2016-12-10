weeb : weeb.scm gtk3_bindings.h
	csc -vk weeb.scm -C "`pkg-config --cflags gtk+-3.0`" \
		-L "`pkg-config --libs gtk+-3.0`"

