#!/bin/sh

major=20170411
minor=2245
micro="stable"

SDK_VERSION="10.2"
DEV_ROOT=/Applications/Xcode.app/Contents/Developer
TC_ROOT=$DEV_ROOT/Toolchains/XcodeDefault.xctoolchain

PLATFORM=
WORK_ROOT=`pwd`
SOURCE=$WORK_ROOT/x264-snapshot-${major}-${minor}-${micro}
OUTPUT=$WORK_ROOT/output_ios

FAT=$OUTPUT/x264-fat
THIN=$OUTPUT/x264-thin

archs="i386 x86_64 armv7 armv7s arm64"

COMPILE="y"
LIPO="y"

if [ "$*" ]
then
    if [ "$*" = "lipo" ]
        then
        # skip compile
        COMPILE=
    else
        archs="$*"
        if [ $# -eq 1 ]
        then
        # skip lipo
        LIPO=
        fi
    fi
fi

if [ "$COMPILE" ]
then
    cd $SOURCE

    for a in $archs; do
      case $a in
        arm*)
          PLATFORM="iPhoneOS"
          HOST=arm-apple-darwin
          ;;
        i386|x86_64)
          PLATFORM="iPhoneSimulator"
          HOST=$a-apple-darwin
          ;;
      esac

      SYS_ROOT=$DEV_ROOT/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDK_VERSION}.sdk

      PREFIX=$THIN/$a && rm -rf $PREFIX && mkdir -p $PREFIX

      COMMONFLAGS="-arch $a -pipe -gdwarf-2 -no-cpp-precomp -isysroot ${SYS_ROOT} -fPIC"

      export CC="$TC_ROOT/usr/bin/clang "
      export AS="$TC_ROOT/usr/bin/as"

      export LDFLAGS="${COMMONFLAGS} -fPIC"
      export CFLAGS="${COMMONFLAGS} -fvisibility=hidden"
      export CXXFLAGS="${COMMONFLAGS} -fvisibility=hidden -fvisibility-inlines-hidden"

      ./configure \
        --host=$HOST \
        --sysroot=$SYS_ROOT \
        --prefix="$PREFIX" \
        --enable-pic \
        --enable-static \
        --disable-asm

      make && make install && make clean

      done
fi

if [ "$LIPO" ]
then
    echo "start building fat binaries..."
    mkdir -p $FAT/lib
    set - $archs
    CWD=`pwd`
    cd $THIN/$1/lib
    for LIB in *.a
    do
    cd $CWD
    lipo -create `find $THIN -name $LIB` -output $FAT/lib/$LIB
    done

    cd $CWD
    cp -rf $THIN/$1/include $FAT
fi