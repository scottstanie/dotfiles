#!/bin/bash

# Note: I got these from running the following:
# comm -23 <(apt-mark showmanual | sort -u) <(gzip -dc /var/log/installer/initial-status.gz | sed -n 's/^Package: //p' | sort -u)

sudo apt-get update

for package in anki apt-file curl cython3 deja-dup-backend-gvfs fdupes gfortran git gnome-tweak-tool google-chrome-stable htop lynx m4 python3-gdal python3-pip python-pip scons skypeforlinux slack-desktop texlive-full texstudio tomate-gtk tomate-indicator-plugin vim vim-gnome xclip; do
  sudo apt-get -y install $package
done

