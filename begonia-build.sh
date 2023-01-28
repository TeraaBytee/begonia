#!/bin/bash
#
#   Copyright (C) 2022 TeraaBytee <terabyte3766@gmail.com>
#
#   SPDX-License-Identifier: Apache-2.0

MainPath=$(pwd)
DTC=$(pwd)/../DragonTC
Gcc64=$(pwd)/../gcc64
Gcc=$(pwd)/../gcc
GCC64=$(pwd)/../GCC64
GCC=$(pwd)/../GCC
AnyKernel=$(pwd)/../AnyKernel3

# Telegram message
# echo "your bot token" > .bot_token
# echo "your group or channel chat id" > .chat_id
BOT_TOKEN="$(pwd)/.bot_token"
CHAT_ID="$(pwd)/.chat_id"

msg(){
    curl -X POST https://api.telegram.org/bot$(cat .bot_token)/sendMessage \
    -d disable_web_page_preview=true \
    -d chat_id=$(cat .chat_id) \
    -d parse_mode=html \
    -d text="$1"
}

upload(){
    curl -F parse_mode=markdown https://api.telegram.org/bot$(cat .bot_token)/sendDocument \
    -F chat_id=$(cat .chat_id) \
    -F document=@$FILE \
    -F caption="$1"
}

if [[ -e $BOT_TOKEN && -e $CHAT_ID ]]; then
    msg "<code>Time to building kernel</code>"
fi

# Make zip
MakeZip(){
    if [ ! -d $AnyKernel ]; then
        git clone https://github.com/TeraaBytee/AnyKernel3 -b master $AnyKernel
        cd $AnyKernel
    else
        cd $AnyKernel
        git fetch origin master
        git checkout master
        git reset --hard origin/master
    fi
    cp -af $MainPath/out/arch/arm64/boot/Image.gz-dtb $AnyKernel
    sed -i "s/kernel.string=.*/kernel.string=$HeadCommit test by $KBUILD_BUILD_USER/g" anykernel.sh
    zip -r9 $MainPath/"[$TIME][$Compiler][Q-OSS]-$KERNEL_VERSION-$HeadCommit.zip" * -x .git README.md *placeholder
    cd $MainPath
}

# Clone Compiler
Clone_DTC() {
    if [[ -e $BOT_TOKEN && -e $CHAT_ID ]]; then
        msg "<code>clone compiler . . .</code>"
    fi
    if [ ! -d $DTC ]; then
        git clone --depth=1 https://github.com/TeraaBytee/DragonTC $DTC
    else
        cd $DTC
        git fetch origin 10.0
        git checkout FETCH_HEAD
        git branch -D 10.0
        git branch 10.0 && git checkout 10.0
        cd $MainPath
    fi
    if [ ! -d $gcc64 ]; then
        git clone --depth=1 https://github.com/TeraaBytee/aarch64-linux-android-4.9 $gcc64
    else
        cd $gcc64
        git fetch origin master
        git checkout FETCH_HEAD
        git branch -D master
        git branch master && git checkout master
        cd $MainPath
    fi
    if [ ! -d $gcc ]; then
        git clone --depth=1 https://github.com/TeraaBytee/arm-linux-androideabi-4.9 $gcc
    else
        cd $gcc
        git fetch origin master
        git checkout FETCH_HEAD
        git branch -D master
        git branch master && git checkout master
        cd $MainPath
    fi
    Compiler_Version=$($DTC/bin/clang --version | grep version)
}
Clone_GCC() {
    if [[ -e $BOT_TOKEN && -e $CHAT_ID ]]; then
        msg "<code>clone compiler . . .</code>"
    fi
    if [ ! -d $GCC64 ]; then
        git clone --depth=1 https://github.com/mvaisakh/gcc-arm64 -b gcc-master $GCC64
    else
        cd $GCC64
        git fetch origin gcc-master
        git checkout FETCH_HEAD
        git branch -D gcc-master
        git branch gcc-master && git checkout gcc-master
        cd $MainPath
    fi
    if [ ! -d $GCC ]; then
        git clone --depth=1 https://github.com/mvaisakh/gcc-arm -b gcc-master $GCC
    else
        cd $GCC
        git fetch origin gcc-master
        git checkout FETCH_HEAD
        git branch -D gcc-master
        git branch gcc-master && git checkout gcc-master
        cd $MainPath
    fi
    Compiler_Version="$($GCC64/bin/*gcc --version | grep gcc)"
}
# Kernel config
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_HOST="$(hostname)"
export KBUILD_BUILD_USER="TeraaBytee"
Defconfig="begonia_user_defconfig"
Branch=$(git branch | grep '*' | awk '{ print $2 }')
Changelogs=$(git log --oneline -5 --no-decorate)
HeadCommit=$(git log --pretty=format:'%h' -1)
KERNEL_VERSION="4.14.$(cat "$MainPath/Makefile" | grep "SUBLEVEL =" | sed 's/SUBLEVEL = *//g')"

# Cleaning
rm -rf out

if [[ -e $BOT_TOKEN && -e $CHAT_ID ]]; then
    msg "$(
    printf "<b>Device</b>: <code>Redmi Note 8 Pro [BEGONIA]</code>\n"
    printf "<b>Branch</b>: <code>$Branch</code>\n"
    printf "<b>Build User</b>: <code>$KBUILD_BUILD_USER</code>\n"
    printf "<b>Build Host</b>: <code>$KBUILD_BUILD_HOST</code>\n"
    printf "<b>Kernel Version</b>: <code>$KERNEL_VERSION</code>\n"
    printf "<b>Compiler</b>:\n<code>$Compiler_Version</code>\n\n"
    printf "<b>Changelogs</b>:\n<code>$Changelogs</code>\n\n"
    )"
fi

# Building
if [[ -e $BOT_TOKEN && -e $CHAT_ID ]]; then
    msg "<code>building . . .</code>"
fi
TIME=$(date +"%d%m")
TIME_START() {
    BUILD_START=$(date +"%s")
}
# Build choices
Build_DTC() {
    make  -j$(nproc --all)  O=out $Defconfig
    exec 2> >(tee -a out/error.log >&2)
    make  -j$(nproc --all)  O=out \
                            PATH="$DTC/bin:/$Gcc64/bin:/$Gcc/bin:/usr/bin:$PATH" \
                            LD_LIBRARY_PATH="$DTC/lib64:$LD_LIBRABRY_PATH" \
                            CC=clang \
                            LD=ld.lld \
                            CROSS_COMPILE=aarch64-linux-android- \
                            CROSS_COMPILE_ARM32=arm-linux-androideabi- \
                            CLANG_TRIPLE=aarch64-linux-gnu-
}
Build_GCC() {
    make  -j$(nproc --all)  O=out $Defconfig
    exec 2> >(tee -a out/error.log >&2)
    make  -j$(nproc --all)  O=out \
                            PATH="$GCC64/bin:$GCC/bin:/usr/bin:$PATH" \
                            AR=aarch64-elf-ar \
                            NM=llvm-nm \
                            LD=ld.lld \
                            OBCOPY=llvm-objcopy \
                            OBJDUMP=aarch64-elf-objdump \
                            STRIP=aarch64-elf-strip \
                            CROSS_COMPILE=aarch64-elf- \
                            CROSS_COMPILE_ARM32=arm-eabi-
}

TIME_FINNISH() {
    BUILD_END=$(date +"%s")
    BUILD_DIFF=$((BUILD_END - BUILD_START))
    BUILD_TIME="$((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) second(s)"
}

Finnish() {
    if [ -e $MainPath/out/arch/arm64/boot/Image.gz-dtb ]; then
        MakeZip
        if [[ -e $BOT_TOKEN && -e $CHAT_ID ]]; then
            FILE=$(echo $MainPath/*$Compiler*$HeadCommit.zip)
            upload "$(date)"
            msg "<b>Build success in</b>:%0A<code>$BUILD_TIME</code>"
        else
            echo "Build success in: $BUILD_TIME"
        fi
    else
        if [[ -e $BOT_TOKEN && -e $CHAT_ID ]]; then
            FILE="out/error.log"
            upload "$(date)"
            msg "<b>Build fail in</b>:%0A<code>$BUILD_TIME</code>"
        else
            echo "Build fail in: $BUILD_TIME"
        fi
    fi
}

case $1 in
    -d | --dtc )
        Compiler="DTC"
        Clone_DTC
        TIME_START
        Build_DTC
        TIME_FINNISH
        Finnish
        ;;
    -g | --gcc )
        Compiler="GCC"
        Clone_GCC
        TIME_START
        Build_GCC
        TIME_FINNISH
        Finnish
        ;;
    * )
        echo "Usage: begonia-build.sh [OPTION]..."
        echo "Option:"
        echo "    -d,--dtc        build using DragonTC compiler"
        echo "    -g,--gcc        build using GCC compiler"
        ;;
esac

