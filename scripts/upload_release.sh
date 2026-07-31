#!/bin/bash

source $(dirname ${0})/lib.sh

SBCL_VERSION=${1}
REVISION=${2}

git config --global --add safe.directory "${GITHUB_WORKSPACE}"
git config user.name "Shubhamkar Ayare"
git config user.email "digikar@proton.me"

RELEASE="${SBCL_VERSION}+r${REVISION}"
TAG="v${RELEASE}"

mkdir tarballs
mv linux-tarballs/* tarballs/
mv darwin-tarballs/* tarballs/
mv windows-tarballs/* tarballs/

touch notes.md
cat tarballs/linux-notes.md >> notes.md
cat tarballs/darwin-notes.md >> notes.md
cat tarballs/windows-notes.md >> notes.md

gh release create \
   ${TAG} \
   --latest \
   --title "SBCL ${RELEASE}" \
   --notes-file notes.md \
   tarballs/sbcl-*
