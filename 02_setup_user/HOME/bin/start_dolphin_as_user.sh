#!/bin/bash

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 USERNAME" >&2
  exit 1
fi

export SU_USER=$1

pactl load-module module-native-protocol-tcp
xhost si:localuser:$SU_USER
su $SU_USER sh -c "dolphin ${@:2}"
