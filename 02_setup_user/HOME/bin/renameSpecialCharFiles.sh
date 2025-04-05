#!/bin/bash

#Folder
find -depth -type d -execdir rename 's/Ä/Ae/g;
s/Ö/Oe/g;
s/Ü/ue/g;
s/ä/ae/g;
s/à/a/g;
s/è/e/g;
s/é/e/g;
s/ö/oe/g;
s/ü/ue/g;
s/@/at/g;
s/#/_/g;
s/\"/-/g;
s/\[/-/g;
s/\]/-/g;
s/\302\201/ue/g;
s/\302\204/ae/g;
s/\302\224/oe/g;
s/\201/ue/g;
s/\224/oe/g;
s/\204/ae/g;
s/\232/Ue/g;
s/\207/./g;
s/\200/./g;
s/ï¿½/ae/g;
s/�/oe/g;
s/ /_/g;
s/,/_/g;
s/!/_/g;
s/\?/_/g;
s/\)/-/g;
s/\(/-/g;
s/\:/-/g;
s/;/_/g;
s/\&/and/g;
s/\x27/_/g;
s/%20/_/g;
s/▶/_/g;
s/\x3D/_/g;
s/\xDF/ss/g;
' '{}' \;
# not in list:
#   s/\+/and/g;


#File
find . -type f -exec rename 's/Ä/Ae/g;
s/Ö/Oe/g;
s/Ü/ue/g;
s/ä/ae/g;
s/à/a/g;
s/è/e/g;
s/é/e/g;
s/ö/oe/g;
s/ü/ue/g;
s/@/at/g;
s/#/_/g;
s/\"/-/g;
s/\[/-/g;
s/\]/-/g;
s/\302\201/ue/g;
s/\302\204/ae/g;
s/\302\224/oe/g;
s/\201/ue/g;
s/\224/oe/g;
s/\204/ae/g;
s/\232/Ue/g;
s/\207/./g;
s/\200/./g;
s/ï¿½/ae/g;
s/�/oe/g;
s/ /_/g;
s/,/_/g;
s/!/_/g;
s/\?/_/g;
s/\)/-/g;
s/\(/-/g;
s/\:/-/g;
s/;/_/g;
s/\&/and/g;
s/\x27/_/g;
s/%20/_/g;
s/▶/_/g;
s/\x3D/_/g;
s/\xDF/ss/g;
' '{}' \;
# not in list:
#   s/\+/and/g;


#awk '
#{
#        match ($0,/.*\//)
#        name = substr ($0,RLENGTH+1)
#        pfad = substr ($0,1,RLENGTH)
#        gsub (/%20/,"_",name)
#        print "mv '\''" $0 "'\'' '\''" pfad name "'\''"
#}' | sh -ev 


find . -type f -exec rename 's/\.\.\.\.\.\././g;
s/\.\.\.\.\.\././g;
s/\.\.\.\.\././g;
s/\.\.\.\././g;
s/\.\.\././g;
s/\.\././g;
s/_______/_/g;
s/______/_/g;
s/_____/_/g;
s/____/_/g;
s/___/_/g;
s/__/_/g;
' '{}' \;


