#!/bin/bash
# input
#   Comando "Glog"
#   arg1
#     comando
#   arg2
#     Mensaje
#   arg3 (opcional)
#     tipo de mensaje. 
#     default: INFO
#     opciones: INF WAR ERR
# output
#   archivo de log

#ejemplo de uso
#./glog auxiliarCommand mensaje1 WAR
#./glog anOtherCommand mensaje2 ERR
#./glog auxiliarCommand mensaje3



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

generar_log () {

    TIPOS=("INF" "WAR" "ERR")
    TIPO_DEFAULT="INF"
    TIMESTAMP=`date +"%Y-%m-%d_%H-%M-%S"`
    array_contains TIPOS $TIPO  && TIPO=$TIPO || TIPO=$TIPO_DEFAULT
    AUTOR=$(whoami);
    log="$TIMESTAMP - $TIPO - $AUTOR - $COMANDO - $MENSAJE"

    echo "$log" >> "$LOGFILE"

}


controlar_crecimiento_logfile (){
    #TODO: crecimiento se debe controlar con peso en kb (pag 24, punto 17)
    #LOGFILE_SIZE=`wc -l "$LOGFILE" | xargs | cut -f1 -d' '`
    #echo $LOGFILE
    LOGFILE_SIZE=$(du --summarize --block-size=1024  "$LOGFILE" | cut -f1 |  sed 's/^[ \t]*//;s/[ \t]*$//')
    #echo "log peso $LOGFILE_SIZE"
    if [[ "$LOGFILE_SIZE" -gt $LOGSIZE ]]; then
        LINEAS=$(wc -l "$LOGFILE" | cut -f1 -d ' ')
        LINEAS_QUE_QUEDAN=$(expr $LINEAS / 2)
        tail -$LINEAS_QUE_QUEDAN "$LOGFILE" > "${LOGFILE}save"
        mv "${LOGFILE}save" "$LOGFILE"
    fi

}
############################################

if [ $# -gt 3 -o $# -lt 2 ]
then
    ./glog glog "$1 - Cantidad de parametros no valida." ERROR
    exit 1
fi

COMANDO="$1"
MENSAJE="$2"
TIPO="$3"
#TODO: Lo importante es que SIEMPRE adopte un mecanismo para mantener controlado el tamaño de un
#log. Puede adoptar cualquier mecanismo, aclare en Hipótesis y Aclaraciones Globales cual fue el
#que adoptó
LOGSIZE=$LOGSIZE #"100"
#LOGSAVE="50" #logs que se guardan al reiniciar archivo
LOGDIR=$LOGDIR #"log/"
cd ..
mkdir -p "$LOGDIR"
LOGFILE="${LOGDIR}$COMANDO.log"
GENERAL_LOGFILE="${LOGDIR}salida.log"

generar_log
controlar_crecimiento_logfile

exit 0
