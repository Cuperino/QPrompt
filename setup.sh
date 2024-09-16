#!/bin/bash

#**************************************************************************
#
# QPrompt
# Copyright (C) 2024 Javier O. Cordero Pérez
#
# This file is part of QPrompt.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 3 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#**************************************************************************

ARCHITECTURE="$(uname -m)"
QT_VER=6.7.2
echo -e "\nArchitecture: $ARCHITECTURE"

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
   PLATFORM="linux"
   if [ "$ARCHITECTURE" == "aarch64" ]; then
       COMPILER="gcc_arm64"
   else
       COMPILER="gcc"
   fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macos"
    COMPILER="macos"
elif [[ "$OSTYPE" == "win32" || "$OSTYPE" == "msys" ]]; then
    PLATFORM="windows"
    if [ "$ARCHITECTURE" == "aarch64" ]; then
        COMPILER="msvc2019_arm64"
    else
        COMPILER="msvc2019_64"
    fi
elif [[ "$OSTYPE" == "freebsd"* ]]; then
    PLATFORM="freebsd"
    COMPILER="gcc"
else
    PLATFORM="unix"
    COMPILER="gcc"
fi

CMAKE_CONFIGURATION_TYPES="Debug;Release;RelWithDebInfo;MinSizeRel"
CMAKE_BUILD_TYPE=$1
if [ "$CMAKE_BUILD_TYPE" == "" ]; then
    CMAKE_BUILD_TYPE="RelWithDebInfo"
fi
CMAKE_PREFIX_PATH=$2
if [ "$CMAKE_PREFIX_PATH" == "" ]
    then
    if [[ "$OSTYPE" == "win32" ]]; then
        CMAKE_PREFIX_PATH="C:\\Qt\\$QT_VER\\$COMPILER\\"
    elif [[ "$OSTYPE" == "msys" ]]; then
        CMAKE_PREFIX_PATH=/c/Qt/$QT_VER/$COMPILER/
    else
        CMAKE_PREFIX_PATH=~/Qt/$QT_VER/$COMPILER/
    fi
fi

cat << EOF
usage: $0 <CMAKE_BUILD_TYPE> <CMAKE_PREFIX_PATH> [CLEAR | CLEAR_ALL]

Settings:
 * CMAKE_BUILD_TYPE: $CMAKE_BUILD_TYPE
 * CMAKE_PREFIX_PATH: $CMAKE_PREFIX_PATH

Setup script for building QPrompt
This script assumes you've already installed the following dependencies:

 For all platforms:
 > Git
 > Bash
 > Python 3
 > Qt 6 ($QT_VER used by default)

 For Linux:
 > build-essential
 > cmake

 For macOS:
 > CMake
 > Homebrew

 For Windows:
 > Visual Studio (Community Edition)
 >> Desktop Development with C++
 >> C++ ATL
 >> Windows SDK
EOF

QT_MAJOR_VERSION=6
CLEAR_ARG="${@: -1}"
if [ "$CLEAR_ARG" == "CLEAR" ]
    then
    CLEAR=true
    CLEAR_ALL=false
elif [ "$CLEAR_ARG" == "CLEAR_ALL" ]
    then
    CLEAR=true
    CLEAR_ALL=true
else
    CLEAR=false
    CLEAR_ALL=false
fi

# Constants
CMAKE_INSTALL_PREFIX="install"
mkdir -p "$CMAKE_INSTALL_PREFIX"

echo -e "\nBuild directory is ./build"
if $CLEAR_ALL # QPrompt and dependencies
    then
    rm -dRf ./build ./install
elif $CLEAR # QPrompt
    then
    rm -dRf ./build
fi
mkdir -p build install

if [[ "$PLATFORM" == "macos" ]]; then
    brew install ninja
elif [[ "$PLATFORM" == "windows" ]]; then
    winget install -e --id Kitware.CMake
    winget install -e --id Ninja-build.Ninja
    winget install -e --id NSIS.NSIS
fi

echo "Downloading git submodules"
git submodule update --init --recursive

python3 -m venv venv
if [[ "$PLATFORM" == "windows" ]]; then
    source venv/Scripts/activate
else
    source venv/bin/activate
fi
python -m pip install --upgrade pip
python -m pip install -r requirements.txt

if [[ "$PLATFORM" == "windows" ]]; then
    # Initialize MSVC environment variables
    "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" amd64
    # Download and extract gettext binary
    FILENAME="gettext0.21-iconv1.16-shared-64.zip"
    curl -Lo build/$FILENAME "https://github.com/mlocati/gettext-iconv-windows/releases/download/v0.21-v1.16/$FILENAME"
    unzip -o build/$FILENAME -d "$CMAKE_PREFIX_PATH"
fi

# VCPKG
# Setup VCPKG
./3rdparty/vcpkg/bootstrap-vcpkg.sh -disableMetrics
if [[ "$PLATFORM" == "windows" ]]; then
VCPKG=./3rdparty/vcpkg/vcpkg.exe
else
VCPKG=./3rdparty/vcpkg/vcpkg
fi
# Install VCPKG packages
$VCPKG install --x-install-root $CMAKE_PREFIX_PATH gettext gettext-libintl
# Copy installed packages into install prefix
for package in ./3rdparty/vcpkg/packages/*; do
    echo $package
    cp -rf $package/* $CMAKE_PREFIX_PATH
done

# KDE Frameworks
tier_0="
    ./3rdparty/extra-cmake-modules
"
tier_1="
    ./3rdparty/kcoreaddons
    ./3rdparty/ki18n
    ./3rdparty/kcrash
    ./3rdparty/kirigami
"
tier_2="
"
tier_3="
"
for dependency in $tier_0 $tier_1 $tier_2 $tier_3; do
    echo -e "\n\n~~~" $dependency "~~~\n"
    if $CLEAR_ALL
    then
        rm -dRf $dependency/build
    fi
    cmake -DCMAKE_CONFIGURATION_TYPES=$CMAKE_CONFIGURATION_TYPES -DBUILD_TESTING=OFF -BUILD_QCH=OFF -DCMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH -DCMAKE_INSTALL_PREFIX=$CMAKE_INSTALL_PREFIX -B ./$dependency/build ./$dependency/
    cmake --build ./$dependency/build --config $CMAKE_BUILD_TYPE
    cmake --install ./$dependency/build
    cp -r $CMAKE_INSTALL_PREFIX $CMAKE_PREFIX_PATH
done

echo "QHotkey"
if $CLEAR_ALL
then
    rm -dRf 3rdparty/QHotkey/build
fi
cmake -DCMAKE_CONFIGURATION_TYPES=$CMAKE_CONFIGURATION_TYPES -DCMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH -DCMAKE_INSTALL_PREFIX=$CMAKE_INSTALL_PREFIX -DBUILD_SHARED_LIBS=ON -DQT_DEFAULT_MAJOR_VERSION=${QT_MAJOR_VERSION} -B ./3rdparty/QHotkey/build ./3rdparty/QHotkey/
cmake --build ./3rdparty/QHotkey/build --config $CMAKE_BUILD_TYPE
cmake --install ./3rdparty/QHotkey/build
cp -r $CMAKE_INSTALL_PREFIX $CMAKE_PREFIX_PATH

echo "QPrompt"
cmake -DCMAKE_CONFIGURATION_TYPES=$CMAKE_CONFIGURATION_TYPES -DCMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH -DCMAKE_INSTALL_PREFIX=$CMAKE_INSTALL_PREFIX -B ./build .
cmake --build ./build --config $CMAKE_BUILD_TYPE
cmake --install ./build
cp -r $CMAKE_INSTALL_PREFIX $CMAKE_PREFIX_PATH

# Copy Qt libraries into install directory
if [[ "$PLATFORM" == "windows" ]]; then
    PATH=$PATH:"C:\Program Files (x86)\NSIS"
    $CMAKE_PREFIX_PATH/bin/windeployqt.exe ./install/bin/$CMAKE_BUILD_TYPE/QPrompt.exe
elif [[ "$PLATFORM" == "macos" ]]; then
    $CMAKE_PREFIX_PATH/bin/macdeployqt ./install/QPrompt
# elif [[ "$PLATFORM" == "linux" ]]; then
#     $CMAKE_PREFIX_PATH/bin/linuxdeployqt ./install/bin/qprompt
fi
