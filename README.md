Fucking weeb
============

A library manager for animu (and TV shows, and whatever).

## Why

I have my series split over different hard drives,
in nested directories with names like
"[Underwater] Something Something [Batch]".
That makes it hard to browse.

I then also have to remember what's the last episode I watched.
And if I'm watching that series with different
audio/subtitle settings than the default, change those.

Wouldn't it be cool if I could save all this information
in an easy to navigate library thingy? That's what this is.

![screenshot](https://www.cosarara.me/jaume/images/fucking_weeb_screenshot.png)\


Now go watch [the video].

## Extra Features

* Show posters
* Automatically find posters in [TMDb]
* Drag and drop posters from your browser and your file manager
* Did I say it displays posters?
* Set a video player command, which can be overriden
per show
* It tries to get the show name from the directory name
* It follows the XDG standards with regard to config files and such

## Installing

Oh yeah before you ask, I've only run this on linux.
Have fun on other OSes.

The easy way should be to download a release and just run that.
But those aren't done yet, so let's go with the hard way for now.

Fucking weeb is written in [CHICKEN scheme], and uses
Gtk+ 3 as well as a bunch of dependencies (eggs).

So how do we build this?

First install chicken scheme and gtk3.

Then install (using chicken-install):

* bind
* http-client
* uri-common
* openssl
* medea

Also you probably want to first do [this][chicken-install],
but using chicken/8 instead of 6.

Then build the thing:

$ make

To run it:

$ ./weeb

You can then symlink or copy the binary to somewhere in your $PATH.

The first time you run it, it will complain about having no database
file and create one for you.

## TO-DOs/known bugs

* Make the thing faster
* I've had it crash in the middle of downloads (something something C_temporary_stack_bottom)

[the video]: http://www.cosarara.me/jaume/files/videos/fucking-weeb.webm
[TMDb]: https://www.themoviedb.org/
[CHICKEN scheme]: https://call-cc.org/
[chicken-install]: https://wiki.call-cc.org/man/4/Extensions#changing-repository-location
