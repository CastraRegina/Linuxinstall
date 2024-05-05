#!/bin/bash

export _DEVICES="/dev/nvme0n1 /dev/nvme1n1"
export _LOG_FOLDER="$HOME/logs/disk_infos/"

[ -d "${_LOG_FOLDER}" ] || mkdir -p "${_LOG_FOLDER}"

DATETIME=$(date +%Y%m%d_%H%M%S)


for i in $_DEVICES ; do
  if $( blkid | grep -q ${i} ) ; then
    outFile=${_LOG_FOLDER}${DATETIME}$(echo "${i}" | sed -e 's|/|_|g').txt 
    echo "-----------------------------------------------------"
    echo ${i} : ${outFile}
    smartctl -x $i | grep "Critical Warning"
    smartctl -x $i | grep "Media and Data Integrity Errors"
    smartctl -x $i | grep "Warning  Comp. Temperature"
    smartctl -x $i | grep "Critical Comp. Temperature"
    nvme smart-log $i | grep "endurance group critical warning"
    echo "-----------------------------------------------------"
    echo

    echo "=====================================================" >> ${outFile}
    echo "smartctl -x $i"                                        >> ${outFile}
    echo "=====================================================" >> ${outFile}
    smartctl -x $i                                               >> ${outFile}
    
    echo "=====================================================" >> ${outFile}
    echo "smartctl -d sat -x $i"                                 >> ${outFile}
    echo "=====================================================" >> ${outFile}
    smartctl -d sat -x $i >> ${outFile}
    
    echo "=====================================================" >> ${outFile}
    echo "nvme list"                                             >> ${outFile}
    echo "=====================================================" >> ${outFile}
    nvme list >> ${outFile}
    
    echo "=====================================================" >> ${outFile}
    echo "nvme smart-log $i"                                     >> ${outFile}
    echo "=====================================================" >> ${outFile}
    nvme smart-log $i >> ${outFile}

    echo "=====================================================" >> ${outFile}
    echo "nvme error-log $i"                                     >> ${outFile}
    echo "=====================================================" >> ${outFile}
    nvme error-log $i >> ${outFile}

    echo "=====================================================" >> ${outFile}
    echo "nvme self-test-log $i"                                     >> ${outFile}
    echo "=====================================================" >> ${outFile}
    nvme self-test-log $i >> ${outFile}

  fi
done 

