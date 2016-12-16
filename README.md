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

![Screenshot](https://www.cosarara.me/jaume/images/fucking_weeb_screenshot.png)


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

### Arch

If you run arch, you are in luck, because so do I.
[Have a PKGBUILD!](https://aur.archlinux.org/packages/weeb-git/)
(not it's also in the arch/ directory in this same repo, so you can
just get that).

### Other *nix

Fucking weeb is written in [CHICKEN scheme], and uses
Gtk+ 3 as well as a bunch of dependencies (eggs).

The building dependencies are:

* gtk3
* chicken

Plus the following chicken eggs:

* bind
* http-client
* uri-common
* openssl
* medea

#### Quick instructions

Install gtk3 and chicken from your distro's repositories, then run:

    $ make deps-and-all
    $ sudo make install

Fucking Weeb will be installed in /opt/weeb with a symlink in /usr/bin.
You can uninstall chicken too, if you want.

The first time you run it, it will complain about having no database
file and create one for you (in your $XDG_HOME).

#### Long instructions

You can either bundle everything into one package
(like we did in the quick instructions),
so that the only dependency is gtk3, or make a normal development build, which
will link to the files inside your $CHICKEN_REPOSITORY.

If you are going to be doing more than one build, the deps-and-all target
is very inefficient (since it downloads the dependencies to a temporary directory
every time).

Read the makefile to see how it works.

I keep my chicken eggs in _~/.local/lib/chicken/8_.
Read [this][chicken-install] for the original instructions.

_bind_ tries to install a binary in /usr/bin even with the $CHICKEN_REPOSITORY
env var, and that's why need to use -p unless we want to run chicken-install as root.

You could also install everything as root in /usr/ (that's the default if you don't
set a $CHICKEN_REPOSITORY).

Anyway, once you have the dependencies installed with chicken-install, and
in either CHICKEN_REPOSITORY or the global path, you can run either
_make_ or _make deployable_ and either will work.
The former will give you a _weeb_ binary in the current directory which
you can move around but links to your installed eggs, while the
second will create a _weeb_ directory with a package you can
move around to any system that has a compatible libc and gtk3 installed.

## TO-DOs/known bugs

* The logo. Why didn't we start with the logo?
* I've had it crash at random times (something something C_temporary_stack_bottom)
* The code is not pretty. Don't judge me as a programmer for it
  (it was my first scheme project after all)
* Need a better poster-not-found image

[the video]: http://www.cosarara.me/jaume/files/videos/fucking-weeb.webm
[TMDb]: https://www.themoviedb.org/
[CHICKEN scheme]: https://call-cc.org/
[chicken-install]: https://wiki.call-cc.org/man/4/Extensions#changing-repository-location
