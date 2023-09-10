#!/bin/bash

# Some general variables
DIR=`readlink -f .`
PARENT_DIR=`readlink -f ${DIR}/..`

export ARCH=arm64
export DEFCONFIG=enchilada_defconfig
export COMPILER=clang
export COMPILERDIR=$PARENT_DIR/clang-latest
export AARCH64DIR=$PARENT_DIR/aarch64-linux-android-4.9
export ARM32DIR=$PARENT_DIR/arm-linux-androideabi-4.9
export PATH=${COMPILERDIR}/bin:${PATH}
export VARIANT="OnePlus6_6T"

# LLVM=1 makes kernel use clang instead of gcc
# LLVM_IAS makes kernel use clang integrated assembler
export LLVM=1
export LLVM_IAS=1

# Color
ON_BLUE=`echo -e "\033[44m"`	# On Blue
RED=`echo -e "\033[1;31m"`	# Red
BLUE=`echo -e "\033[1;34m"`	# Blue
GREEN=`echo -e "\033[1;32m"`	# Green
Under_Line=`echo -e "\e[4m"`	# Text Under Line
STD=`echo -e "\033[0m"`		# Text Clear

# Functions
pause(){
  read -p "${RED}$2${STD}Press ${BLUE}[Enter]${STD} key to $1..." fackEnterKey
}

toolchain(){
  if [ ! -d $PARENT_DIR/aarch64-linux-android-4.9 ]; then
    pause 'clone toolchain aarch64-linux-android-4.9 cross compiler'
    git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9 $PARENT_DIR/aarch64-linux-android-4.9
  fi
  if [ ! -d $PARENT_DIR/arm-linux-androideabi-4.9 ]; then
    pause 'clone toolchain arm-linux-androideabi-4.9 32-bit cross compiler'
    git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9 $PARENT_DIR/arm-linux-androideabi-4.9
  fi
}

clang(){
  if [ ! -d $PARENT_DIR/clang-latest ]; then
    pause 'clone prebuilt crDroid Clang/LLVM 17.0.2 compiler'
    git clone --depth=1 https://gitlab.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-r487747c $PARENT_DIR/clang-latest
  fi
}

clean(){
  echo "${GREEN}***** Cleaning in Progress *****${STD}"
  make clean -j$(nproc) O=out
  make mrproper -j$(nproc) O=out
  echo "${GREEN}***** Cleaning Done *****${STD}"
}

build_kernel() {
  echo "${GREEN}***** Compiling kernel for OnePlus6(T) *****${STD}"
  [ ! -d "out" ] && mkdir out
  make O=out ARCH=${ARCH} ${DEFCONFIG}
  make -j$(nproc) O=out \
	ARCH=${ARCH} \
	CC=${COMPILER} \
	CROSS_COMPILE=${AARCH64DIR}/bin/aarch64-linux-android- \
	CROSS_COMPILE_ARM32=${ARM32DIR}/bin/arm-linux-androideabi- \
	CLANG_TRIPLE=${COMPILERDIR}/bin/aarch64-linux-gnu-
}

anykernel3(){
  if [ ! -d $PARENT_DIR/AnyKernel3 ]; then
    pause 'clone AnyKernel3 - Flashable Zip Template'
    git clone https://github.com/osm0sis/AnyKernel3 $PARENT_DIR/AnyKernel3
  fi
  [ -e $PARENT_DIR/${VARIANT}_kernel.zip ] && rm $PARENT_DIR/${VARIANT}_kernel.zip
  if [ -e $DIR/out/arch/arm64/boot/Image.gz-dtb ]; then
    cd $PARENT_DIR/AnyKernel3
    git reset --hard
    cp $DIR/out/arch/arm64/boot/Image.gz-dtb Image.gz-dtb
    sed -i "s/ExampleKernel by osm0sis @ xda-developers/AntiGravity Kernel by TQMatvey @ Telegram/g" anykernel.sh
    sed -i "s/=maguro/=OnePlus6/g" anykernel.sh
    sed -i "s/=toroplus/=OnePlus6T/g" anykernel.sh
    sed -i "s/=toro/=/g" anykernel.sh
    sed -i "s/=tuna/=/g" anykernel.sh
    sed -i "s/is_slot_device=0/is_slot_device=1/g" anykernel.sh
    sed -i "s/\/dev\/block\/platform\/omap\/omap_hsmmc\.0\/by-name\/boot/boot/g" anykernel.sh
    sed -i "s/backup_file/#backup_file/g" anykernel.sh
    sed -i "s/replace_string/#replace_string/g" anykernel.sh
    sed -i "s/insert_line/#insert_line/g" anykernel.sh
    sed -i "s/append_file/#append_file/g" anykernel.sh
    sed -i "s/patch_fstab/#patch_fstab/g" anykernel.sh

    zip -r9 $PARENT_DIR/${releasefilename}.zip * -x .git README.md *placeholder
    cd $DIR
  else
    echo 'Done building flashable zip'
  fi
}

build_kernel_sdm845(){
  build_kernel
  curtime=`date +"%m_%d_%H%M"`
  releasefilename=AntiGravity_Test_${curtime}_${VARIANT}
  anykernel3
  clean
}

# Run once
toolchain
clang

# Show menu
show_menus(){
  echo "${ON_BLUE} B U I L D - M E N U ${STD}"
  echo "1. ${Under_Line}B${STD}uild kernel for ${VARIANT}"
  echo "2. ${Under_Line}C${STD}lean"
  echo "3. Make ${Under_Line}f${STD}lashable zip"
  echo "4. E${Under_Line}x${STD}it"
}

# Read input
read_options(){
  local choice
  read -p "Enter choice [ 1 - 4] " choice
  case $choice in
    1|b|B) build_kernel_sdm845 ;;
    2|c|C) clean ;;
    3|f|F) anykernel3;;
    4|x|X) exit 0;;
    *) pause 'return to Main menu' 'Invalid option, '
  esac
}

# Trap CTRL+C, CTRL+Z and quit singles
trap '' SIGINT SIGQUIT SIGTSTP

# Step # Main logic - infinite loop
while true
do
  show_menus
  read_options
done
