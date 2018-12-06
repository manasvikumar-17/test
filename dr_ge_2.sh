#!/bin/bash -e
#
#  Copyright (c) 2014, Facebook, Inc.
#  All rights reserved.
#
#  This source code is licensed under the BSD-style license found in the
#  LICENSE file in the root directory of this source tree. An additional grant
#  of patent rights can be found in the PATENTS file in the same directory.
#

echo
echo This script will install fblualib and all its dependencies.
echo It has been tested on Ubuntu 13.10 and Ubuntu 14.04, Linux x86_64.
echo

set -e
set -x
set TORCH_BUILD_DIR = "~/torch/lib"

# Find the include files
set TORCH_TH_INCLUDE_DIR = "${TORCH_BUILD_DIR}/include/TH"
set TORCH_THC_INCLUDE_DIR = "${TORCH_BUILD_DIR}/include/THC"
set TORCH_THC_UTILS_INCLUDE_DIR = "$ENV{HOME}/pytorch/torch/lib/THC"

set Torch_INSTALL_INCLUDE = "${TORCH_BUILD_DIR}/include" ${TORCH_TH_INCLUDE_DIR} ${TORCH_THC_INCLUDE_DIR} ${TORCH_THC_UTILS_INCLUDE_DIR}

# Find the libs. We need to find libraries one by one.
set TORCH_LIB_HINTS = "${TORCH_BUILD_DIR}" "/usr/local/lib" "/root/torch/install/lib"
find_library (THC_LIBRARIES NAMES THC THC.1 PATHS ${TORCH_BUILD_DIR} PATH_SUFFIXES lib)
find_library (TH_LIBRARIES NAMES TH TH.1 PATHS ${TORCH_BUILD_DIR} PATH_SUFFIXES lib)

if [[ $(arch) != 'x86_64' ]]; then
    echo "x86_64 required" >&2
    exit 1
fi

issue=$(cat /etc/issue)
extra_packages=
current=0
if [[ $issue =~ ^Ubuntu\ 13\.10 ]]; then
    :
elif [[ $issue =~ ^Ubuntu\ 14 ]]; then
    extra_packages=libiberty-dev
elif [[ $issue =~ ^Ubuntu\ 15\.04 ]]; then
    extra_packages=libiberty-dev
elif [[ $issue =~ ^Ubuntu\ 16\.04 ]]; then
    extra_packages=libiberty-dev
    current=1
else
    echo "Ubuntu 13.10, 14.*, 15.04 or 16.04 required" >&2
    exit 1
fi

dir=$(mktemp --tmpdir -d fblualib-build.XXXXXX)

echo Working in $dir
echo
cd $dir

echo Installing required packages
echo
sudo apt-get install -y \
    git \
    curl \
    wget \
    g++ \
    zip \
    unzip \
    automake \
    autoconf \
    autoconf-archive \
    libtool \
    libboost-all-dev \
    libevent-dev \
    libdouble-conversion-dev \
    libgoogle-glog-dev \
    libgflags-dev \
    liblz4-dev \
    liblzma-dev \
    libsnappy-dev \
    make \
    zlib1g-dev \
    binutils-dev \
    libjemalloc-dev \
    $extra_packages \
    flex \
    bison \
    libkrb5-dev \
    libsasl2-dev \
    libnuma-dev \
    pkg-config \
    libssl-dev \
    libedit-dev \
    libmatio-dev \
    libpython-dev \
    libpython3-dev \
    python-numpy

echo
echo Cloning repositories
echo
if [ $current -eq 1 ]; then
    git clone --depth 1 https://github.com/facebook/folly
    git clone --depth 1 https://github.com/facebook/fbthrift
    git clone https://github.com/facebook/thpp
    git clone https://github.com/facebook/fblualib
    git clone https://github.com/facebook/wangle
else
    git clone -b v0.35.0  --depth 1 https://github.com/facebook/folly
    git clone -b v0.24.0  --depth 1 https://github.com/facebook/fbthrift
    git clone -b v1.0 https://github.com/facebook/thpp
    git clone -b v1.0 https://github.com/facebook/fblualib
fi

curl -s https://raw.githubusercontent.com/torch/distro/master/install-deps | bash
git clone https://github.com/torch/distro.git ~/torch --recursive
cd ~/torch; ./install.sh

echo
echo Building folly
echo

cd $dir/folly/folly
wget https://github.com/google/googletest/archive/release-1.8.0.tar.gz && \
tar zxf release-1.8.0.tar.gz && \
rm -f release-1.8.0.tar.gz && \
cd googletest-release-1.8.0 && \
cmake . && \
make && \
make install
sudo ldconfig # reload the lib paths after freshly installed folly. fbthrift needs it.



echo
echo 'Installing TH++'
echo

cd $dir/thpp/thpp
./build.sh

echo
echo 'Installing FBLuaLib'
echo

cd $dir/fblualib/fblualib
./build.sh

echo
echo 'All done!'
echo
