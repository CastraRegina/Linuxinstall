#!/bin/bash

# -------------------------------------------------------------------------------
# Copy files into Desktop folder
# -------------------------------------------------------------------------------


set -e   # immediately exit if any command has a non-zero exit status
set -u   # treat unset variables as an error and exit immediately


# -------------------------------------------------------------------------------
# Source 000_common.sh
# -------------------------------------------------------------------------------
. ./000_common.sh


srcDir=./HOME/Desktop
dstDir=$HOME/Schreibtisch


# -------------------------------------------------------------------------------
# Create destination dir if it does not exist 
# -------------------------------------------------------------------------------
if ! [ -d "${dstDir}" ] ; then
  mkdir -p "${dstDir}"
fi


# -------------------------------------------------------------------------------
# Copy the files 
# -------------------------------------------------------------------------------
if [ -d "${srcDir}" ] ; then
  updateDir "${srcDir}" "${dstDir}"
fi

