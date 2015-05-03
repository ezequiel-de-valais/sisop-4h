#!/bin/bash

#===========================================================
#
# ARCHIVO: ProPro.sh
#
# DESCRIPCION: Protocoliza los archivos que se encuentran 
#  dentro de la carpeta $GRUPO$NOVEDIR$ACEPDIR
# 
# AUTOR: Solotun, Roberto. 
# PADRON: 85557
#
#===========================================================

# Llama al log para grabar
# $1 = mensaje
# $2 = tipo (INF WAR ERR)

function grabarLog {
   ./Glog.sh "ProPro" "$1" "$2"

}

# Valida si el ambiente está inicializado

function validarEjecucionIniPro {

  variables=($GRUPO $BINDIR $MAEDIR $ACEPDIR $RECHDIR $PROCDIR)
  for var in ${variables[*]}; do
      if [ -z "$var" ]; then
         return 0
      fi
  done  
  return 1
}

# Verifica que el archivo aceptado no haya sido procesado anteriormente

function verificarDuplicado {
    grabarLog "$2/$1" INFO
  if [ -f "$2/$1" ]; then
    return 0
  else
    return 1
  fi

}

# Verifica que la combinacion COD_NORMA/COD_EMISOR sea valida

function verificarNormaEmisor {
  if [ $res -eq 0 ]; then
    return 0
  else
    return 1
  fi

}

# Funcion principal

function main {
   
   validarEjecucionIniPro
   exit
   validacion="$?"

   if [ $validacion -eq 1 ]; then 
      grabarLog "El ambiente no está inicializado." "ERR"
      grabarLog "No se ejecutará el programa ProPro." "ERR"
   else
      grabarLog "Inicio de ProPro." "INF"
      cantidadArchivos=`find $GRUPO$ACEPDIR -type f | wc -l`
      grabarLog "Cantidad de archivos a procesar: $cantidadArchivos" "INF"
      MAESTROGESTIONES="$GRUPO$MAEDIR/gestiones.mae"
      while read line || [[ -n "$line" ]]; do 
          gestiones+=$(echo $line | cut -d ";" -f1) 
          gestiones+=" "
      done < $MAESTROGESTIONES
      for gestion in ${gestiones[*]}; do
          if [ `ls $GRUPO$ACEPDIR | grep -c $gestion` != 0 ]; then
             if [ `ls $GRUPO$ACEPDIR/$gestion | cut -d"_" -f1 | grep -c $gestion` != 0 ]; then #Hay al menos un arch de la gestion
		fechasordenadas=$(ls $GRUPO$ACEPDIR/$gestion | cut -d"_" -f5 | sort -k1.7 -k1.4 -k1.1)
		for fecha in $fechasordenadas; do
		    for archivo in `ls $GRUPO$ACEPDIR/$gestion | grep $fecha`; do
          	    	grabarLog "Archivo a procesar: $archivo" "INF"
          	    	verificarDuplicado "$archivo" "$GRUPO$PROCDIR/proc"
          	    	if [ $? == 0 ]; then   #Si esta duplicado
             		    grabarLog "Se rechaza el archivo por estar DUPLICADO." "WAR"
             		    ./Mover.sh "$GRUPO$ACEPDIR/$gestion/$archivo" "$GRUPO$RECHDIR" "ProPro"
          	    	else
                      norma=$(echo $archivo | cut -d "_" -f 2)
                      emisor=$(echo $archivo | cut -d "_" -f 3)
                      verificarNormaEmisor $norma $emisor
                      if [ $? == 0 ]; then   #La combinacion COD_NORMA/COD_EMISOR no se encuentra en la tabla nxe.tab
                        grabarLog "Se rechaza el archivo. Emisor no habilitado en este tipo de norma." "WAR"
                        Mover.sh "$GRUPO$ACEPDIR/$gestion/$archivo" "$GRUPO$RECHDIR" "ProPro"
          	    	    else
        			           #TODO Falta la validación por registro
        	     		       echo -e "Falta la validación por registro." 
          	    	    fi
          	    	fi
		    done
      		done
	     fi
	  fi
      done
   fi 

}

main