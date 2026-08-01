#!/bin/bash

source $(dirname ${0})/lib.sh

SBCL_HOST=${1}
SBCL_VERSION=${2}
ASDF_VERSION=${3}
REVISION=${4}
export CUSTOM_LIBDIR=${5}
if [[ ! -d "${CUSTOM_LIBDIR}" ]]; then
    die "Directory does not exist: CUSTOM_LIBDIR=${CUSTOM_LIBDIR}"
fi

cd sbcl

# Prevent SBCL build from generating a version string from git
rm -rf .git
# Override SBCL lisp-implementation-version
echo "\"${SBCL_VERSION}+r${REVISION}\"" > version.lisp-expr

# Update ASDF
pushd contrib/asdf
./pull-asdf.sh "${ASDF_VERSION}"
popd

UNAME=$(uname -s)

# Link runtime with goodies and overwrite the original
if [ "$UNAME" == Linux ]; then
    export SYS_LIBDIR="/usr/lib/"
    LIBZSTD=$(find $SYS_LIBDIR -name "libzstd.a" | head -1)
    # Quick hack, not safe for cross-compiling.
    sed -i "s:-lzstd:$LIBZSTD:" src/runtime/Config.*

    LIBFIXPOSIX=${CUSTOM_LIBDIR}/libfixposix.a
    LIBCRYPTO=$(find $SYS_LIBDIR -name "libcrypto.a" | head -1)
    LIBSSL=$(find $SYS_LIBDIR -name "libssl.a" | head -1)
    LIBTLS=$(find $SYS_LIBDIR -name "libtls.a" | head -1)

    export WHOLE_ARCHIVES="-Wl,--whole-archive $LIBFIXPOSIX $LIBCRYPTO $LIBSSL $LIBTLS"

    SBCL_HOST="${SBCL_HOST} --noinform --no-userinit"
    SBCL_BUILD_OPTIONS="--with-sb-core-compression \
    --with-sb-linkable-runtime \
    --without-gencgc --with-mark-region-gc \
    --without-sb-eval \
    --with-sb-fasteval"

elif [ "$UNAME" == Darwin ]; then
    export SYS_LIBDIR="$(brew --prefix)"
    LIBZSTD=$(find $SYS_LIBDIR -name "libzstd.a" | head -1)
    # Quick hack, not safe for cross-compiling.
    sed -i '' "s:-lzstd:$LIBZSTD:" src/runtime/Config.*

    LIBFIXPOSIX=${CUSTOM_LIBDIR}/libfixposix.a
    LIBCRYPTO=$(find $SYS_LIBDIR -name "libcrypto.a" | head -1)
    LIBSSL=$(find $SYS_LIBDIR -name "libssl.a" | head -1)
    LIBTLS=$(find $SYS_LIBDIR -name "libtls.a" | head -1)

    # -force_load only works on one library at a time
    export WHOLE_ARCHIVES="-Wl,-force_load $LIBFIXPOSIX -Wl,-force_load $LIBCRYPTO -Wl,-force_load $LIBSSL -Wl $LIBTLS"

    SBCL_HOST="${SBCL_HOST} --noinform --no-userinit"
    SBCL_BUILD_OPTIONS="--with-sb-core-compression \
    --with-sb-linkable-runtime \
    --without-gencgc --with-mark-region-gc \
    --without-sb-eval \
    --with-sb-fasteval"


elif [[ "$UNAME" == CYGWIN* || "$UNAME" == MINGW* ]] ; then

    UNAME=Windows

    export SYS_LIBDIR="/mingw64/lib"
    LIBZSTD=${SYS_LIBDIR}/libzstd.a
    # Quick hack, not safe for cross-compiling.
    sed -i "s:-lzstd:$LIBZSTD:" src/runtime/Config.*
    LIBSSL=${SYS_LIBDIR}/libssl.a
    LIBTLS=${SYS_LIBDIR}/libtls.a
    LIBCRYPTO="${SYS_LIBDIR}/libcrypto.a ${SYS_LIBDIR}/libcrypt32.a"

    export WHOLE_ARCHIVES="$LIBSSL -Wl,--no-whole-archive $LIBCRYPTO"

    SBCL_HOST="/mingw64/bin/sbcl --noinform --no-userinit"
    SBCL_BUILD_OPTIONS="--fancy --with-sb-linkable-runtime"
fi

cp ../scripts/COPYING.zstd ./

./make.sh --xc-host="$SBCL_HOST" $SBCL_BUILD_OPTIONS

make -C src/runtime -f binaries.mk sbcl.extras
mv -vf src/runtime/sbcl.extras src/runtime/sbcl

mkdir -vp third_party/include
if [[ "$UNAME" == "Linux" || "$UNAME" == "Darwin" ]] ; then
    # Include libfixposix headers
    cp -av ../destdir/usr/local/include/* third_party/include/
else
    touch third_party/include/empty
fi

cd ..

case $(uname -m) in
    x86_64) ARCH="x86-64" ;;
    arm64|aarch64) ARCH="arm64";;
    *) ARCH=$(uname -m) ;;
esac


# Build source distribution
# Despite the name, the source distributions are not identical
SBCLDIST=sbcl-${SBCL_VERSION}+r${REVISION}-$ARCH-$(echo $UNAME | tr '[:upper:]' '[:lower:]')
mv -v sbcl "${SBCLDIST}"
"${SBCLDIST}"/source-distribution.sh "${SBCLDIST}"
bzip2 "${SBCLDIST}"-source.tar

# Build binary distribution
"${SBCLDIST}"/binary-distribution.sh "${SBCLDIST}"
bzip2 "${SBCLDIST}"-binary.tar

echo "###################################################"
echo "Created ${SBCLDIST}-source.tar.bz2"
echo "Created ${SBCLDIST}-binary.tar.bz2"
echo "###################################################"
echo "SRCDIST=${SBCLDIST}-source.tar.bz2" >> ${GITHUB_ENV}
echo "BINDIST=${SBCLDIST}-binary.tar.bz2" >> ${GITHUB_ENV}
