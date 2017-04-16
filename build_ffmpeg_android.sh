#!/bin/sh

major=3
min=2
micro=4
CWD=`pwd`
OUTPUT=`pwd`/output_android

ARCHS="armv7"
ANDROID_MIN_VER=
TOOLCHAIN_VER=
TOOLCHAIN_ARCH=

FF_BUILD_OPT="release"

FF_CFG_FLAGS=
FF_EXTRA_CFLAGS=
FF_EXTRA_LDFLAGS=
FF_DEP_LIBS=
FF_CROSS_PREFIX=

FF_MODULE_DIRS="compat libavcodec libavfilter libavformat libavutil libswresample libswscale"
FF_ASSEMBLER_SUB_DIRS=


for ARCH in $ARCHS
do

    rm -rf ffmpeg-${major}.${min}.${micro} && tar -jxvf ffmpeg-${major}.${min}.${micro}.tar.bz2
    cd ffmpeg-${major}.${min}.${micro}

    case $ARCH in
    x86)
    ANDROID_MIN_VER=9

    TOOLCHAIN_VER="4.9"
    TOOLCHAIN_ARCH="x86"

    FF_CFG_FLAGS="$FF_CFG_FLAGS --arch=x86 --cpu=i686 --enable-yasm"

    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS -march=atom -msse3 -ffast-math -mfpmath=sse"
    FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS"

    FF_CROSS_PREFIX=$ANDROID_NDK/toolchains/${TOOLCHAIN_ARCH}-${TOOLCHAIN_VER}/prebuilt/darwin-x86_64/bin/i686-linux-android

    FF_ASSEMBLER_SUB_DIRS="x86"

    SYSROOT=$ANDROID_NDK/platforms/android-${ANDROID_MIN_VER}/arch-x86
    ;;
    x86_64)
    ANDROID_MIN_VER=21

    TOOLCHAIN_VER="4.9"
    TOOLCHAIN_ARCH="x86_64"

    FF_CFG_FLAGS="$FF_CFG_FLAGS --arch=x86_64 --disable-yasm"

    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS"
    FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS"

    FF_CROSS_PREFIX=$ANDROID_NDK/toolchains/${TOOLCHAIN_ARCH}-${TOOLCHAIN_VER}/prebuilt/darwin-x86_64/bin/x86_64-linux-android

    FF_ASSEMBLER_SUB_DIRS="x86"

    SYSROOT=$ANDROID_NDK/platforms/android-${ANDROID_MIN_VER}/arch-x86_64
    ;;
    arm64)
    ANDROID_MIN_VER=21

    TOOLCHAIN_VER="4.9"
    TOOLCHAIN_ARCH="aarch64-linux-android"

    FF_ASSEMBLER_SUB_DIRS="aarch64 neon"

    FF_CFG_FLAGS="$FF_CFG_FLAGS --arch=aarch64 --enable-yasm"

    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS"
    FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS"

    FF_CROSS_PREFIX=$ANDROID_NDK/toolchains/${TOOLCHAIN_ARCH}-${TOOLCHAIN_VER}/prebuilt/darwin-x86_64/bin/aarch64-linux-android

    SYSROOT=$ANDROID_NDK/platforms/android-${ANDROID_MIN_VER}/arch-arm64
    ;;
    armv7)
    ANDROID_MIN_VER=9

    TOOLCHAIN_VER="4.9"
    TOOLCHAIN_ARCH="arm-linux-androideabi"

    FF_ASSEMBLER_SUB_DIRS="arm"

    FF_CFG_FLAGS="$FF_CFG_FLAGS --arch=arm --cpu=cortex-a8"
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-neon"
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-thumb"

    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS  -march=armv7-a -mcpu=cortex-a8 -mfpu=vfpv3-d16 -mfloat-abi=softfp -mthumb"
    FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS -Wl,--fix-cortex-a8"

    FF_CROSS_PREFIX=$ANDROID_NDK/toolchains/${TOOLCHAIN_ARCH}-${TOOLCHAIN_VER}/prebuilt/darwin-x86_64/bin/arm-linux-androideabi

    SYSROOT=$ANDROID_NDK/platforms/android-${ANDROID_MIN_VER}/arch-arm
    ;;
    esac

    export CC=${FF_CROSS_PREFIX}-gcc
    export LD=${FF_CROSS_PREFIX}-ld
    export STRIP=${FF_CROSS_PREFIX}-strip

    PREFIX=$OUTPUT/ffmpeg-${ARCH}

    rm -rf $PREFIX && mkdir -p $PREFIX

    export COMMON_FF_CFG_FLAGS=
    . $CWD/config/module.sh


    FF_CFLAGS="-O3 -Wall -pipe \
        -std=c99 \
        -ffast-math \
        -fstrict-aliasing -Werror=strict-aliasing \
        -Wno-psabi -Wa,--noexecstack \
        -DANDROID -DNDEBUG"


    FF_CFG_FLAGS="$FF_CFG_FLAGS $COMMON_FF_CFG_FLAGS"

    # Standard options:
    FF_CFG_FLAGS="$FF_CFG_FLAGS --prefix=$PREFIX"

    # Advanced options (experts only):
    FF_CFG_FLAGS="$FF_CFG_FLAGS --cross-prefix=${FF_CROSS_PREFIX}-"
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-cross-compile"
    FF_CFG_FLAGS="$FF_CFG_FLAGS --target-os=linux"
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-pic"


    if [ "$ARCH" = "x86" ]; then
        FF_CFG_FLAGS="$FF_CFG_FLAGS --disable-asm"
    else
        # Optimization options (experts only):
        FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-asm"
        FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-inline-asm"
    fi

    case "$FF_BUILD_OPT" in
        debug)
            FF_CFG_FLAGS="$FF_CFG_FLAGS --disable-optimizations"
            FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-debug"
            FF_CFG_FLAGS="$FF_CFG_FLAGS --disable-small"
        ;;
        release)
            FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-optimizations"
            FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-debug"
            FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-small"
        ;;
    esac

    which $CC
    ./configure $FF_CFG_FLAGS \
        --extra-cflags="$FF_CFLAGS $FF_EXTRA_CFLAGS" \
        --extra-ldflags="$FF_EXTRA_LDFLAGS" \
        --cc=${CC} \
        --sysroot=${SYSROOT}

    cp config.* $PREFIX
    make && make install


    FF_C_OBJ_FILES=
    FF_ASM_OBJ_FILES=
    for MODULE_DIR in $FF_MODULE_DIRS
    do
        C_OBJ_FILES="$MODULE_DIR/*.o"
        if ls $C_OBJ_FILES 1> /dev/null 2>&1; then
            echo "link $MODULE_DIR/*.o"
            FF_C_OBJ_FILES="$FF_C_OBJ_FILES $C_OBJ_FILES"
        fi

        for ASM_SUB_DIR in $FF_ASSEMBLER_SUB_DIRS
        do
            ASM_OBJ_FILES="$MODULE_DIR/$ASM_SUB_DIR/*.o"
            if ls $ASM_OBJ_FILES 1> /dev/null 2>&1; then
                echo "link $MODULE_DIR/$ASM_SUB_DIR/*.o"
                FF_ASM_OBJ_FILES="$FF_ASM_OBJ_FILES $ASM_OBJ_FILES"
            fi
        done
    done

    $CC -lm -lz -shared --sysroot=$SYSROOT -Wl,--no-undefined -Wl,-z,noexecstack $FF_EXTRA_LDFLAGS \
        -Wl,-soname,libffmpeg.so \
        $FF_C_OBJ_FILES \
        $FF_ASM_OBJ_FILES \
        $FF_DEP_LIBS \
        -o $PREFIX/libffmpeg.so

    cd ..
done

