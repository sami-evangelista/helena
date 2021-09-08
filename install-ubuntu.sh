#!/bin/bash
#
# installation script for helena ubuntu machines
#
# author: Jaime Arias (https://github.com/himito)

# Installation Folder
INSTALL_FOLDER=${HOME}

# install dependencies
sudo apt-get update
sudo apt-get install -y make bc git gcc gprbuild gnat mlton python3

# clone helena
git clone https://github.com/sami-evangelista/helena.git \
    "${INSTALL_FOLDER}/helena"

# fix
mkdir -p "${INSTALL_FOLDER}/helena/src/lna/obj"

# compile helena
cd "${INSTALL_FOLDER}/helena/src"
./compile-helena --clean-all
./compile-helena --with-all

# add to PATH
echo "export PATH=${INSTALL_FOLDER}/helena/bin:\$PATH" >> "${HOME}/.bashrc"
source "${HOME}/.bashrc"
