#!/bin/bash

source $(dirname ${0})/lib.sh

SBCL_VERSION=${1}
REVISION=${2}

git config --global --add safe.directory "${GITHUB_WORKSPACE}"
git config user.name "Shubhamkar Ayare"
git config user.email "digikar@proton.me"

RELEASE="${SBCL_VERSION}+r${REVISION}"
TAG="v${RELEASE}"

touch notes.md
cat tarballs/linux-notes.md >> notes.md
cat tarballs/macos-notes.md >> notes.md
cat tarballs/windows-notes.md >> notes.md

gh release create \
   ${TAG} \
   --latest \
   --title "SBCL ${RELEASE}" \
   --notes-file notes.md \
   tarballs/sbcl-${RELEASE}-$(uname -m)-{linux,darwin,windows}-source.tar.bz2 \
   tarballs/sbcl-${RELEASE}-$(uname -m)-{linux,darwin,windows}-binary.tar.bz2
