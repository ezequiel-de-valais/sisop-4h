#!/bin/bash
# Comando "Glog"
# arg1
#   comando
# arg2
#   Mensaje
# arg3 (opcional)
#   tipo de mensaje. 
#   default: debug
#   opciones: debug info warn error

#./bin/Glog.sh auxiliarCommand mensaje1 debug
#./bin/Glog.sh anOtherCommand mensaje2 error
#./bin/Glog.sh auxiliarCommand mensaje3


COMANDO="$1"
MENSAJE="$2"
TIPO="$3"

LOGDIR="/Users/solsticeba8/Documents/Facultad/sistemas operativos/tp/sisop-4h/log/"
#creo path del archivo
mkdir -p "$LOGDIR"

LOGFILE="${LOGDIR}$COMANDO.log"
GENERAL_LOGFILE="${LOGDIR}salida.log"
tipos=("debug" "info" "warn" "error")
TIPO_DEFAULT="debug"

TIMESTAMP=`date +"%Y-%m-%d_%H-%M-%S"`

#revisar si un elemento existe en un array
array_contains () { 
    local array="$1[@]"
    local seeking=$2
    local in=1
    for element in "${!array}"; do
        if [[ $element == $seeking ]]; then
            in=0
            break
        fi
    done
    return $in
}


array_contains tipos $TIPO  && TIPO=$TIPO || TIPO=$TIPO_DEFAULT



log="$TIPO - $TIMESTAMP - $MENSAJE"

echo "$log"
echo "$log" >> "$LOGFILE"

#array_contains tipos "debugs"  && echo yes || echo no    # yes



