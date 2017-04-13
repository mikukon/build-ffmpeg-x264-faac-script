#!/bin/sh

# http://www.linuxfromscratch.org/blfs/view/svn/multimedia/faac.html
# ftp://mirror.ovh.net/gentoo-distfiles/distfiles/

major=1
minor=28
SDK_VERSION="10.2"
DEV_ROOT=/Applications/Xcode.app/Contents/Developer
TC_ROOT=$DEV_ROOT/Toolchains/XcodeDefault.xctoolchain

PLATFORM=
WORK_ROOT=`pwd`
SOURCE=$WORK_ROOT/faac-${major}.${minor}
OUTPUT=$WORK_ROOT/output_ios

FAT=$OUTPUT/faac-fat
THIN=$OUTPUT/faac-thin

COMPILE="y"
LIPO="y"

archs="i386 x86_64 armv7 armv7s arm64"

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
#      rm -rf $SOURCE && mkdir -p $SOURCE && cd $WORK_ROOT && tar xvzf faac-${major}.${minor}.tar.gz
      cd $SOURCE

      export CC="$TC_ROOT/usr/bin/clang -arch $a -isysroot $SYS_ROOT"
      export CXX="$TC_ROOT/usr/bin/clang++ -arch $a -isysroot $SYS_ROOT"
      export CXXFLAGS="-arch $a -isysroot $SYS_ROOT"
      export CFLAGS="-arch $a -isysroot $SYS_ROOT"
      export LDFLAGS="-isysroot $SYS_ROOT"
      export LIBS="-L${SYS_ROOT}/usr/lib"


    #  echo $HOST \
    #        $sys_root \
    #        PREFIX \
    #        $CC \
    #        $CXX \
    #        $CXXFLAGS \
    #        $CFLAGS \
    #        $LDFLAGS \
    #        $LIBS

      chmod +x bootstrap
      ./bootstrap \
        &&./configure \
        --host=$HOST \
        --with-sysroot=$SYS_ROOT \
        --prefix=$PREFIX \
        --disable-shared \
        --enable-static \
        --disable-faac \
        --with-mp4v2 \
        && make && make install && make clean
    done
fi

cd $WORK_ROOT

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