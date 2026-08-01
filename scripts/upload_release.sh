#!/bin/bash

source $(dirname ${0})/lib.sh

SBCL_VERSION=${1}
ASDF_VERSION=${2}
REVISION=${3}

git config --global --add safe.directory "${GITHUB_WORKSPACE}"
git config user.name "Shubhamkar Ayare"
git config user.email "digikar@proton.me"

RELEASE="${SBCL_VERSION}+r${REVISION}"
TAG="v${RELEASE}"

mkdir tarballs
mv tarballs*/* tarballs/

touch notes.md

echo "SBCL ${SBCL_VERSION}, ASDF ${ASDF_VERSION}" > notes.md
cat tarballs/*.md >> notes.md

gh release create \
   ${TAG} \
   --latest \
   --title "SBCL ${RELEASE}" \
   --notes-file notes.md \
   tarballs/sbcl-*
