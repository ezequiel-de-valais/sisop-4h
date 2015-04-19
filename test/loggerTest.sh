#!/bin/bash
#bash conf/general.sh
#echo $PWD
#echo $0
#dirname $0
#basename $0
#bash Glog.sh auxiliarCommand mensaje1 debug
#./Glog.sh auxiliarCommand mensaje2 debug
#./Glog.sh auxiliarCommand mensaje3 debug

#   loggerTest.sh

_DIR=/Users/solsticeba8/Documents/Facultad/sistemas\ operativos/tp/sisop-4h/
cd "$_DIR"
#export Glog=${_DIR}bin/Glog.sh
#log="./Glog.sh"

./bin/Glog.sh auxiliarCommand mensaje1 debug
./bin/Glog.sh anOtherCommand mensaje2 error
./bin/Glog.sh auxiliarCommand mensaje3

