#!/bin/bash

keyname=${KEYNAME:?Must provide KEYNAME}

# Packages & Packages.gz
dpkg-scanpackages --multiversion . > Packages
gzip -k -f Packages

# Release, Release.gpg & InRelease
apt-ftparchive release . > Release
gpg --default-key "${KEYNAME}" -abs -o - Release > Release.gpg
gpg --default-key "${KEYNAME}" --clearsign -o - Release > InRelease

