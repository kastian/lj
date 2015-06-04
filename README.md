# lj
Shell script for posting to livejournal from console.

Any feedback, ideas, fixes, bug reports are welcomed.

## Dependencies
Apart from standart shell builtins also needs [curl](http://curl.haxx.se/), [xmllint](http://xmlsoft.org/xmllint.html) and setted `$EDITOR` environment variable (or run as `EDITOR="your_favorite_editor" lj`).

## Installation
Clone this repository

`$ git clone https://github.com/kastian/lj.git`

and run

`$ ./lj.sh`

or install

`$ sudo make install`

Lj consists only of one executable file so if you'll want to uninstall it you can use

`$ sudo make uninstall`

or just remove file

`$ sudo rm $(which lj)`

## Config

Makes config at `$HOME/.lj/lj`. Some defaults (username, privacy, adult content, etc) could be set there. Config also can be open directly `lj -c` (`$EDITOR $HOME/.lj/lj`)
