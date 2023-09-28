#!/bin/bash

# -------------------------------------------------------------------------------
# This file is sourced by every other script.
#   It mainly sets variables and defines general functions.
# -------------------------------------------------------------------------------


set -e   # immediately exit if any command has a non-zero exit status
set -u   # treat unset variables as an error and exit immediately


# -------------------------------------------------------------------------------
# Define helper function(s)
# -------------------------------------------------------------------------------



# -------------------------------------------------------------------------------
# Set environment variables
# -------------------------------------------------------------------------------
export _LOGPATH=$HOME/logs/install/
export _BINPATH=$HOME/bin




# -------------------------------------------------------------------------------
# Create log & bin path, if path does not yet exist
# -------------------------------------------------------------------------------
[ -d "${_LOGPATH}" ] || mkdir -p "${_LOGPATH}"
[ -d "${_BINPATH}" ] || mkdir -p "${_BINPATH}"




# -------------------------------------------------------------------------------
# Helper function to copy/update a single file
#     copy a file specified by <$1=fullSrcFilepath> to <$2=fullDstDir>
#     if a destination-file already exists a backup is stored
# -------------------------------------------------------------------------------
function updateFile () {
  fullSrcFilepath="$1"
  fullDstDir="$2"
  
  datetime=$(date +"%Y%m%d-%H%M%S")
  file=$(basename "${fullSrcFilepath}")
  fullDstFilepath="${fullDstDir}"/"${file}"
  fullBckFilepath="${fullDstFilepath}"_"${datetime}"

  # create destination directory if it does not exist:
  [ ! -d "${fullDstDir}" ] && mkdir -p "${fullDstDir}"
  
  if [ -f "${fullDstFilepath}" ] ; then
    # file already exists in destination -> save a backup if it is different:
    if ! cmp -s "${fullSrcFilepath}" "${fullDstFilepath}" ; then
      # src file differs from destination file so create backup and then copy:
      mv "${fullDstFilepath}" "${fullBckFilepath}" 
      cp "${fullSrcFilepath}" "${fullDstDir}" 
    fi
  else
    # destination file does not exist yet --> just copy it to destination:
    cp "${fullSrcFilepath}" "${fullDstDir}" 
  fi
 
}
export -f updateFile



# -------------------------------------------------------------------------------
# Helper function to copy/update all files from <srcdir> to <dstdir>
#     copy all files from sourcefolder <$1=srcdir> to <$2=dstdir>
#     if a destination-file already exists a backup is stored
# -------------------------------------------------------------------------------
function updateDir () {
  export srcDir="$1"
  export dstDir="$2"
  oldDir="${PWD}"

  if [ "${srcDir}" == "${srcDir#/}" ] ; then
    # make it an absolute path:
    export srcDir="${oldDir}"/"${srcDir}" 
  fi
  if [ "${dstDir}" == "${dstDir#/}" ] ; then
    # make it an absolute path:
    export dstDir="${oldDir}"/"${dstDir}" 
  fi

  # remove / slash at end of srcDir and dstDir:
  export srcDir=$(echo "${srcDir}" | sed 's!/$!!')  
  export dstDir=$(echo "${dstDir}" | sed 's!/$!!')  

  cd "${srcDir}"
    # create destination folders (even if empty):
    find . -type d -exec bash -c '
      for filepath do
        relPath=$(echo "${filepath}" | sed "s!^\./!!" )
        [ -z "${relPath}" ] && fullDstDir="${dstDir}" || fullDstDir="${dstDir}"/"${relPath}"
        #echo "fullDstDir      ${fullDstDir}"
        mkdir -p "${fullDstDir}"
      done
    ' exec-sh {} +
   
    # copy the files into the destination folders:
    find . -type f -exec bash -c '
      for filepath do
        fullSrcFilepath="${srcDir}"/$(echo "${filepath}" | sed "s!^\./!!" )
        relPath=$(dirname "${filepath}" | sed "s!^\./!!" )
        [ -z "${relPath}" ] && fullDstDir="${dstDir}" || fullDstDir="${dstDir}"/"${relPath}"

        #echo "filepath        ${filepath}"
        #echo "relPath         ${relPath}"
        #echo "fullSrcFilepath ${fullSrcFilepath}" 
        #echo "fullDstDir      ${fullDstDir}"
        #echo "-------------------------------------"

        updateFile "${fullSrcFilepath}" "${fullDstDir}" 
      done
    ' exec-sh {} +
  cd "${oldDir}"
}
export -f updateDir
