# jesse's dotfiles

i use this repo to set up new macOS and Linux development machines. Windows is not supported.

## installation

Clone the repository recursively and run the platform installer:

_note: do not blindly install this on your own system. this is for fresh installs and contains my preferred defaults_

```bash
git clone --recurse-submodules https://github.com/jesses-code-adventures/.dotfiles ~/.dotfiles
chmod +x ~/.dotfiles/install
~/.dotfiles/install
```

The Linux installer expects Mise and the base build tools installed by the `dev-box` repository. Existing files replaced by symlinks are retained with a `.pre-dotfiles` suffix.
