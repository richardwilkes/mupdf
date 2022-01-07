#! /usr/bin/env bash
set -eo pipefail

MUPDF_VERSION=1.19.0
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

case $(uname -s) in
Darwin*)
  OS_TYPE=darwin
  ORIG_LIB_NAME=libmupdf.a
  ORIG_LIB_NAME_THIRD=libmupdf-third.a
  case $(uname -m) in
  x86_64*)
    DEST_LIB_NAME=libmupdf_darwin_amd64.a
    DEST_LIB_NAME_THIRD=libmupdftp_darwin_amd64.a
    export MACOSX_DEPLOYMENT_TARGET=10.13
    ;;
  arm*)
    DEST_LIB_NAME=libmupdf_darwin_arm64.a
    DEST_LIB_NAME_THIRD=libmupdftp_darwin_arm64.a
    export MACOSX_DEPLOYMENT_TARGET=11
    ;;
  esac
  XCFLAGS=-mmacosx-version-min=${MACOSX_DEPLOYMENT_TARGET}
  ;;
Linux*)
  OS_TYPE=linux
  ORIG_LIB_NAME=libmupdf.a
  ORIG_LIB_NAME_THIRD=libmupdf-third.a
  DEST_LIB_NAME=libmupdf_linux.a
  DEST_LIB_NAME_THIRD=libmupdftp_linux.a
  ;;
MINGW*)
  OS_TYPE=windows
  ORIG_LIB_NAME=libmupdf.a
  ORIG_LIB_NAME_THIRD=libmupdf-third.a
  DEST_LIB_NAME=libmupdf_windows.a
  DEST_LIB_NAME_THIRD=libmupdftp_windows.a
  ;;
*)
  echo "Unsupported OS"
  false
  ;;
esac

if [ ! -e mupdf-${MUPDF_VERSION}-source.tar.xz ]; then
  curl https://mupdf.com/downloads/archive/${MUPDF_SRC}.tar.xz -o ${MUPDF_SRC}.tar.xz
fi

if [ ! -e ${MUPDF_SRC} ]; then
  tar xzf ${MUPDF_SRC}.tar.xz
fi

/bin/rm -rf ${MUPDF_DIST} \
  ${MUPDF_SRC}/resources/fonts/droid \
  ${MUPDF_SRC}/resources/fonts/han \
  ${MUPDF_SRC}/resources/fonts/noto \
  ${MUPDF_SRC}/resources/fonts/sil

mkdir -p ${MUPDF_DIST}

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
make HAVE_X11=no \
  HAVE_GLUT=no \
  XCFLAGS="${XCFLAGS}" \
  prefix=${MUPDF_DIST} \
  generate \
  install
mv ${MUPDF_DIST}/lib/${ORIG_LIB_NAME} ${MUPDF_DIST}/lib/${DEST_LIB_NAME}
mv ${MUPDF_DIST}/lib/${ORIG_LIB_NAME_THIRD} ${MUPDF_DIST}/lib/${DEST_LIB_NAME_THIRD}
