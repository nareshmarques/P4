#!/bin/bash

# Make pipeline return code the last non-zero one or zero if all the commands return zero.
set -o pipefail

# Base name for temporary files
base=/tmp/$(basename $0).$$ 

# Ensure cleanup of temporary files on exit
trap cleanup EXIT
cleanup() {
   \rm -f $base.*
}

if [[ $# != 5 ]]; then
   echo "$0 fm mfcc_order melfilter_bank_order input.wav output.mfcc"
   exit 1
fi

fm=$1
mfcc_order=$2
melfilter_bank_order=$3
inputfile=$4
outputfile=$5

UBUNTU_SPTK=0
if [[ $UBUNTU_SPTK == 1 ]]; then
   # In case you install SPTK using debian package (apt-get)
   X2X="sptk x2x"
   FRAME="sptk frame"
   WINDOW="sptk window"
   MFCC="sptk mfcc"
else
   # or install SPTK building it from its source
   X2X="x2x"
   FRAME="frame"
   WINDOW="window"
   MFCC="mfcc"
fi

# Main command for feature extration
sox $inputfile -t raw -e signed -b 16 - | $X2X +sf | $FRAME -l 240 -p 80 | 
   $MFCC -s $fm -l 180 -m $mfcc_order -n $melfilter_bank_order > $base.mfcc || exit 1
   

# Our array files need a header with the number of cols and rows:
ncol=$((mfcc_order)) # mfcc p =>  (a0 a1 a2 ... ap-1) 
nrow=`$X2X +fa < $base.mfcc | wc -l | perl -ne 'print $_/'$ncol', "\n";'`

# Build fmatrix file by placing nrow and ncol in front, and the data after them
echo $nrow $ncol | $X2X +aI > $outputfile
cat $base.mfcc >> $outputfile
