# jesse's dotfiles

i use this repo to set up new machines. currently it supports fresh osx installs, it will support linux, it will not support windows at this stage.

## installation

on a new mac, run git --version so that you're prompted to install the developer tools. then, run the following commands.

_note: do not blindly install this on your own system. this is for fresh installs and contains my preferred defaults_

```bash
git clone --recurse-submodules github.com/jesses-code-adventures/.dotfiles ~/.dotfiles
chmod +x ~/.dotfiles/install
~/.dotfiles/install
```
