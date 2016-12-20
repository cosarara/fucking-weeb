# Windows Installation Guide
## Dependencies
### Cygwin
* make
* libgtk3_0
* chicken
* openssl-devel (openssl should already be installed)
* libgtk3-devel
* xorg-server
* xinit

Grab [cygwin](https://cygwin.com/install.html) and install the above packages using the setup*.exe file.

### Chicken
* bind
* http-client
* uri-common
* openssl
* medea

You can install the eggs by doing the following:
Note: Open the cygwin terminal and execute the command there
```
$ chicken-install.exe bind http-client uri-common openssl medea
```

## Compilation
Open cygwin and execute the following commands.
It is assumed that you are using bash as your shell. If you're using another shell that doesn't use ~/.bashrc, please modify the line that adds "export DISPLAY=:0" to your shell configuration file.
```
$ cd "/home/$USER/"
$ git clone https://github.com/cosarara97/fucking-weeb.git
$ cd fucking-weeb
$ make
$ echo "export DISPLAY=:0" >> ~/.bashrc
$ startxwin ./weeb.exe
```
Because Windows is terminally shit, we can't do ```make install``` because the resulting symlink will be broken (nor can you create your own symlink because startxwin doesn't play nice with the symlink).

Fucking Weeb is almost ready to be used now.

To use mpv with Fucking Weeb, you need to use a special script to launch mpv (because Fucking Weeb passes a cygwin path to mpv and mpv doesn't work with cygwin paths).

Place the following in a file called whatever, wherever:
```sh
#!/bin/sh

file_path=$(cygpath -w "$1")

mpv.exe "$file_path"
```
IMPORTANT: You should have mpv.exe in your PATH environment variable (or just change mpv.exe in the script to the actual location of mpv.exe).
I named the file mpv.sh and I placed it in my ~/bin directory (Note: ~ doesn't point to the /home/$USER directory).

Now, in the settings menu for Fucking Weeb, set the path for the Video Player to the mpv.sh file.

Technically you should be able to do the same for MPC-HC.
