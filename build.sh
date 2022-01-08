#! /usr/bin/env bash
set -eo pipefail

MUPDF_VERSION=1.19.0
BASE_DIR=$(realpath .)
MUPDF_SRC=mupdf-${MUPDF_VERSION}-source
MUPDF_DIST=$(realpath dist)

for arg in "$@"; do
  case "$arg" in
  --clean | -c) CLEAN=restore ;;
  --CLEAN | -C) CLEAN=full ;;
  --help | -h)
    echo "$0 [options]"
    echo "  -c, --clean Remove the distribution and build directories (no build)"
    echo "  -C, --CLEAN Remove all downloaded and built files and directories (no build)"
    echo "  -h, --help This help text"
    exit 0
    ;;
  *)
    echo "Invalid argument: $arg"
    exit 1
    ;;
  esac
done

if [ "$CLEAN"x == "fullx" ]; then
  /bin/rm -rf mupdf-*-source.tar.xz mupdf-*-source ${MUPDF_DIST}
  exit 0
fi

if [ "$CLEAN"x == "restorex" ]; then
  /bin/rm -rf ${MUPDF_DIST} mupdf-*-source/build
  exit 0
fi

case $(uname -m) in
x86_64*)
  ARCH=amd64
  export MACOSX_DEPLOYMENT_TARGET=10.13
  ;;
arm*)
  ARCH=arm64
  export MACOSX_DEPLOYMENT_TARGET=11
  ;;
*)
  echo "Unsupported architecture"
  false
  ;;
esac

case $(uname -s) in
Darwin*)
  OS_TYPE=darwin
  OS=darwin
  XCFLAGS=-mmacosx-version-min=${MACOSX_DEPLOYMENT_TARGET}
  ;;
Linux*)
  OS_TYPE=linux
  OS=linux
  ;;
MINGW*)
  OS_TYPE=windows
  OS=mingw64
  EXTRA_BUILD_FLAGS="CC=gcc"
  ;;
*)
  echo "Unsupported OS"
  false
  ;;
esac

ORIG_LIB_NAME=libmupdf.a
ORIG_LIB_NAME_THIRD=libmupdf-third.a
DEST_LIB_NAME=libmupdf_${OS_TYPE}_${ARCH}.a
DEST_LIB_NAME_THIRD=libmupdftp_${OS_TYPE}_${ARCH}.a

if [ ! -e mupdf-${MUPDF_VERSION}-source.tar.xz ]; then
  curl https://mupdf.com/downloads/archive/${MUPDF_SRC}.tar.xz -o ${MUPDF_SRC}.tar.xz
fi

if [ ! -e ${MUPDF_SRC} ]; then
  tar xf ${MUPDF_SRC}.tar.xz
fi

/bin/rm -rf ${MUPDF_DIST} \
  ${MUPDF_SRC}/resources/fonts/droid \
  ${MUPDF_SRC}/resources/fonts/han \
  ${MUPDF_SRC}/resources/fonts/noto \
  ${MUPDF_SRC}/resources/fonts/sil

# This is necessary for Windows, which can't handle the long command lines that are generated, so we are shortening them
cd ${MUPDF_SRC}
for f in $(grep -rl 'thirdparty' .); do
  sed -i -e 's/thirdparty/tp/g' $f
done
if [ -e thirdparty ]; then
  mv thirdparty tp
fi
cd ..

XCFLAGS="${XCFLAGS} \
  -DFZ_ENABLE_SPOT_RENDERING=0 \
  -DFZ_ENABLE_XPS=0 \
  -DFZ_ENABLE_SVG=0 \
  -DFZ_ENABLE_CBZ=0 \
  -DFZ_ENABLE_HTML=0 \
  -DFZ_ENABLE_EPUB=0 \
  -DFZ_ENABLE_OCR_OUTPUT=0 \
  -DFZ_ENABLE_DOCX_OUTPUT=0 \
  -DFZ_ENABLE_ODT_OUTPUT=0 \
  -DFZ_ENABLE_JS=0 \
  -DTOFU \
  -DTOFU_CJK"

cd ${MUPDF_SRC}
make OS=${OS} \
  HAVE_X11=no \
  HAVE_GLUT=no \
  HAVE_WIN32=no \
  OUT=build \
  XCFLAGS="${XCFLAGS}" \
  ${EXTRA_BUILD_FLAGS} \
  prefix=${MUPDF_DIST} \
  generate \
  libs
cd ..

mkdir -p ${MUPDF_DIST}/lib
cp -R ${MUPDF_SRC}/include ${MUPDF_DIST}
/bin/rm -rf ${MUPDF_DIST}/include/mupdf/helpers
cd ${MUPDF_DIST}/lib
mkdir mupdf
cd mupdf
ar -x ${BASE_DIR}/${MUPDF_SRC}/build/libmupdf.a
cd ${MUPDF_DIST}/lib
mkdir tp
cd tp
ar -x ${BASE_DIR}/${MUPDF_SRC}/build/libmupdf-third.a
cd ${MUPDF_DIST}/lib
ar -r libmupdf_${OS_TYPE}_${ARCH}.a mupdf/* tp/*
/bin/rm -rf mupdf tp
