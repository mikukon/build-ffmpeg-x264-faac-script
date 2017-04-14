#!/bin/sh  
# LXH,MXY modified


OUTPUT=`pwd`/"output_ios"/
THIN=$OUTPUT/"ffmpeg-thin"
FAT=$OUTPUT/"ffmpeg-fat"
SDK_VERSION="10.2"
FF_VERSION="3.2.4"
PLATFORM=
CPU=
ACH=
VERSION_MIN="6.0"

LIPO=

ARCHS="i386 x86_64 arm64 armv7 armv7s"

# libx264
export X264ROOT=`pwd`/../x264/output_ios/x264-thin
# libfaac
export FAACROOT=`pwd`/../faac/output_ios/faac_thin

export DEVROOT=/Applications/Xcode.app/Contents/Developer



for arch in $ARCHS
do
    rm -rf ffmpeg-${FF_VERSION} && tar -jxvf ffmpeg-${FF_VERSION}.tar.bz2
    cd ffmpeg-${FF_VERSION}

    case $arch in
        arm*)
        PLATFORM="iPhoneOS"
        CPU="cortex-a9"
        ACH=arm
        ;;
        i386|x86_64)
        PLATFORM="iPhoneSimulator"
        CPU=$arch
        ACH=$arch
        ;;
    esac

    PREFIX=${THIN}/$arch
    echo "Prefix-"$PREFIX
    rm -rf $PREFIX && mkdir -p $PREFIX

    export SDKROOT=$DEVROOT/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDK_VERSION}.sdk
    export CC=$DEVROOT/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang
    export AS=$DEVROOT/Toolchains/XcodeDefault.xctoolchain/usr/bin/as

    COMMONFLAGS="-arch $arch -pipe -gdwarf-2 -no-cpp-precomp -isysroot ${SDKROOT}  -fPIC"

    export LDFLAGS="${COMMONFLAGS} -fPIC"
    export CFLAGS="${COMMONFLAGS} -fvisibility=hidden"
    export CXXFLAGS="${COMMONFLAGS} -fvisibility=hidden -fvisibility-inlines-hidden"

    export X264LIB=$X264ROOT/$arch/lib
    export X264INCLUDE=$X264ROOT/$arch/include

    echo $X264INCLUDE $X264LIB
    export FAACLIB=$FAACROOT/$arch/lib
    export FAACINCLUDE=$FAACROOT/$arch/include

    echo "start building $arch..."

#    echo "cpu-"$CPU" ,platform-"$PLATFORM

    ./configure \
    --extra-cflags="-I$X264INCLUDE  -arch $arch -miphoneos-version-min=${VERSION_MIN} -mthumb" \
    --extra-ldflags="-L$X264LIB  -arch $arch -miphoneos-version-min=${VERSION_MIN}" \
    --enable-cross-compile \
    --arch=$ACH \
    --disable-iconv\
    --target-os=darwin \
    --cc=${CC} \
    --disable-asm\
    --sysroot=${SDKROOT} \
    --prefix=$PREFIX \
    --enable-gpl --enable-nonfree --enable-version3 \
    --disable-bzlib \
    --enable-small \
    --disable-vda \
    --disable-encoders \
    --enable-libx264 \
    --enable-encoder=libx264 \
    --enable-encoder=libfaac \
    --disable-muxers \
    --enable-muxer=flv \
    --enable-muxer=mov \
    --enable-muxer=ipod \
    --enable-muxer=mpegts \
    --enable-muxer=psp \
    --enable-muxer=mp4 \
    --enable-muxer=avi \
    --disable-decoders \
    --enable-decoder=aac \
    --enable-decoder=aac_latm \
    --enable-decoder=h264 \
    --enable-decoder=mpeg4 \
    --disable-demuxers --enable-demuxer=flv --enable-demuxer=h264 --enable-demuxer=mpegts --enable-demuxer=avi --enable-demuxer=mpc --enable-demuxer=mov \
    --disable-parsers --enable-parser=aac --enable-parser=ac3 --enable-parser=h264 \
    --disable-protocols --enable-protocol=file --enable-protocol=rtmp --enable-protocol=rtp --enable-protocol=udp \
    --disable-bsfs --enable-bsf=aac_adtstoasc --enable-bsf=h264_mp4toannexb \
    --disable-devices --disable-debug --disable-ffmpeg --disable-ffprobe --disable-ffplay --disable-ffserver --disable-debug

    make
    make install
    make clean
    cd ..
done

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