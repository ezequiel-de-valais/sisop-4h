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

  variables=($GRUPO $BINDIR $MAEDIR $NOVEDIR $ACEPDIR $RECHDIR $PROCDIR)
  for var in ${variables[*]}; do
      if [ -z "$var" ]; then
         return 0
      fi
  done  
  return 1
}

# Verifica que el archivo aceptado no haya sido procesado anteriormente

function verificarDuplicado {

  if [ -f "$2/$1" ]; then
    return 0
  else
    return 1
  fi

}

# Verifica que la combinacion COD_NORMA/COD_EMISOR sea valida

function verificarNormaEmisor {
  nxefile="$GRUPO$MAEDIR/tab/nxe.tab"
  res=$(grep -c "$1;$2" "$nxefile")
  #echo $res
  if [ $res -eq 0 ]; then
    return 0
  else
    return 1
  fi

}

# Genera el archivo de registros rechazados
# $1=registro
# $2=gestion
# $3=motivo
# $4=archivo

function rechazarRegistro {

   registro="$4;"
   registro+="$3;"
   registro+="$1"

   mkdir -p "$GRUPO$NOVEDIR$PROCDIR"
   RECHFILE="$GRUPO$NOVEDIR$PROCDIR/$2.rech"
   echo $registro >> "$RECHFILE"

}

# Genera el archivo de registros historicos
# $1=registro
# $2=gestion
# $3=archivo

function armarRegistroHistorico {

   registro="$3;"
   registro+=$(echo $1 | cut -d";" -f1)";"
   registro+=$(echo $1 | cut -d";" -f2)";"
   registro+=$(echo $1 | cut -d";" -f1 | cut -d"/" -f3)";"
   registro+=$(echo $1 | cut -d";" -f3)";"
   registro+=$(echo $1 | cut -d";" -f4)";"
   registro+=$(echo $1 | cut -d";" -f5)";"
   registro+=$(echo $1 | cut -d";" -f6)";"
   registro+=$(echo $1 | cut -d";" -f7)";"
   registro+=$(echo $1 | cut -d";" -f8)";"
   registro+=$(echo $1 | cut -d";" -f9)";"
   registro+=$(echo $3 | cut -d"_" -f1)";"
   registro+=$(echo $3 | cut -d"_" -f2)";"
   registro+=$(echo $3 | cut -d"_" -f3)

   anioNorma=$(echo $3 | cut -d"_" -f5 | cut -d"-" -f3)
   codNorma=$(echo $3 | cut -d"_" -f2)

   mkdir -p "$GRUPO$NOVEDIR$PROCDIR/$2"
   REGFILE="$GRUPO$NOVEDIR$PROCDIR/$2/$anioNorma.$codNorma"
   echo $registro >> "$REGFILE"

}

# Genera el archivo de registros corrientes
# $1=registro
# $2=gestion
# $3=archivo

function armarRegistroCorriente {

   anio=$(echo $1 | cut -d";" -f1 | cut -d"/" -f3)
   codEmisor=$(echo $3 | cut -d"_" -f3)
   codNorma=$(echo $3 | cut -d"_" -f2)
   
   registro="$3;"
   registro+=$(echo $1 | cut -d";" -f1)";"
   calcularNroNorma "$2" "$anio" "$codEmisor" "$codNorma"
   registro+="$?;"
   registro+="$anio;"
   registro+=$(echo $1 | cut -d";" -f3)";"
   registro+=$(echo $1 | cut -d";" -f4)";"
   registro+=$(echo $1 | cut -d";" -f5)";"
   registro+=$(echo $1 | cut -d";" -f6)";"
   registro+=$(echo $1 | cut -d";" -f7)";"
   registro+=$(echo $1 | cut -d";" -f8)";"
   registro+=$(echo $1 | cut -d";" -f9)";"
   registro+=$(echo $3 | cut -d"_" -f1)";"
   registro+=$(echo $3 | cut -d"_" -f2)";"
   registro+=$(echo $3 | cut -d"_" -f3)

   anioNorma=$(echo $3 | cut -d"_" -f5 | cut -d"-" -f3)
   codNorma=$(echo $3 | cut -d"_" -f2)

   mkdir -p "$GRUPO$NOVEDIR$PROCDIR/$2"
   REGFILE="$GRUPO$NOVEDIR$PROCDIR/$2/$anioNorma.$codNorma"
   echo $registro >> "$REGFILE"

}

# Guarda la tabla axg con los nuevos valores

function guardarNuevaTablaAXG {

   AXGFILE="$GRUPO$MAEDIR/tab/axg.tab"
   ultimoId=0
   for clave in "${!nrosNorma[@]}"; do
	datos=${datosNrosNorma["$clave"]}
        id=$(echo "$datos" | cut -d";" -f1)
        nroViejo=$(echo "$datos" | cut -d";" -f2)
	if [[ "$id" != "" ]]; then
	   registro="$id;"
	   registro+="$clave;"
	   registro+="${nrosNorma["$clave"]};"
           if [[ "$nroViejo" != "${nrosNorma["$clave"]}" ]]; then
	   	registro+=$(whoami)";"
	   	registro+=`date +"%d/%m/%Y"`
	   else
		registro+=$(echo "$datos" | cut -d";" -f3)";"
	   	registro+=$(echo "$datos" | cut -d";" -f4)
           fi
  	   if [[ "$id" > "$ultimoId" ]]; then
 	   	ultimoId=$id
	   fi
   	   echo $registro >> "$AXGFILE"
  	fi
   done
   for clave in "${!nrosNorma[@]}"; do
	datos=${datosNrosNorma["$clave"]}
	id=$(echo "$datos" | cut -d";" -f1)
	if [[ "$id" == "" ]]; then
	   (( ultimoId++ ))
	   registro="$ultimoId;"
	   registro+="$clave;"
	   registro+="${nrosNorma["$clave"]};"
	   registro+=$(whoami)";"
	   registro+=`date +"%d/%m/%Y"`
   	   echo $registro >> "$AXGFILE"
  	fi
   done

   

}

# Valida que la fecha del registro sea válida
# $1=registro
# $2=gestion
# $3=archivo

function validadorFechaRegistro {
   
   aux=$(echo $1 | cut -d";" -f1)
   fecha=$(echo $aux | cut -d"/" -f3)$(echo $aux | cut -d"/" -f2)$(echo $aux | cut -d"/" -f1)
   date --date="$fecha" +"%Y%m%d" 1>/dev/null 2>/dev/null
   fechaValidar=`date --date="$fecha" +"%Y%m%d"`
   if [ $? == 0 ]; then #la fecha es válida
      fechaInicialAux=$(grep "^$2;.*;.*;.*;.*$" "$MAESTROGESTIONES" | cut -d ";" -f 2)
      fechaFinalAux=$(grep "^$2;.*;.*;.*;.*$" "$MAESTROGESTIONES" | cut -d ";" -f 3)
      aux=$(echo $fechaInicialAux | cut -d"/" -f3)$(echo $fechaInicialAux | cut -d"/" -f2)$(echo $fechaInicialAux | cut -d"/" -f1)
      fechaInicial=`date --date="$aux" +"%Y%m%d"`
      if [[ $fechaInicial > $fechaValidar ]]; then
         rechazarRegistro "$1" "$2" "motivo de rechazo = fecha fuera del rango de la gestión" "$3"
         return 1
      else
         if [[ "$fechaFinalAux" != "NULL" ]]; then
            aux=$(echo $fechaFinalAux | cut -d"/" -f3)$(echo $fechaFinalAux | cut -d"/" -f2)$(echo $fechaFinalAux | cut -d"/" -f1)
	    fechaFinal=` date --date="$aux" +"%Y%m%d"`
            if [[ $fechaFinal < $fechaValidar ]]; then
               rechazarRegistro "$1" "$2" "motivo de rechazo = fecha fuera del rango de la gestión" "$3"
               return 1
            fi
         fi
      fi
   else
      rechazarRegistro "$1" "$2" "motivo de rechazo = fecha invalida" "$3"
      return 1
   fi
   return 0

}

# Valida que el nro de norma del registro historico sea válido
# $1=registro
# $2=gestion
# $3=archivo

function validadorNroNormaRegistro {
   
   codNorma=$(echo $1 | cut -d";" -f2)
   if [ $codNorma -le 0 ]; then
      rechazarRegistro "$1" "$2" "motivo de rechazo = numero de norma inválido" "$3"
      return 1
   fi
   return 0

}

# Valida que la firma del registro corriente sea válida
# $1=registro
# $2=gestion
# $3=archivo

function validadorFirmaRegistro {
   
   codEmisor=$(echo $3 | cut -d"_" -f3)
   MAESTROEMISORES="$GRUPO$MAEDIR/emisores.mae"
   firma=$(echo $1 | cut -d";" -f8)
   firmaEmisor=$(grep "$codEmisor" "$MAESTROEMISORES" | cut -d ";" -f3)
   if [ "$firma" != "$firmaEmisor" ]; then
      rechazarRegistro "$1" "$2" "motivo de rechazo = código de firma invalido" "$3"
      return 1
   fi
   return 0

}

# Valida y procesa los registros de un archivo
# $1=archivo a procesar
# $2=gestion

function procesarArchivo {

   while read line || [[ -n "$line" ]]; do 
	validadorFechaRegistro "$line" "$2" "$1"
        if [ $? = 0 ];then
           codNorma=$(echo $line | cut -d";" -f2)
           if [ "$codNorma" != "" ]; then #es un registro histórico
              validadorNroNormaRegistro "$line" "$2" "$1"
              if [ $? = 0 ];then
                 armarRegistroHistorico "$line" "$2" "$1"
              fi
           else #es un registro corriente
              validadorFirmaRegistro "$line" "$2" "$1"
              if [ $? = 0 ];then 
                 armarRegistroCorriente "$line" "$2" "$1"
     	      fi
           fi
        fi
   done < $GRUPO$NOVEDIR$ACEPDIR/$gestion/$1

}

# Calcula el nro de norma
# $1=gestion
# $2=anio
# $3=codEmisor
# $4=codNorma

function calcularNroNorma {

  nroNorma=${nrosNorma["$1;$2;$3;$4"]}
  if [[ "$nroNorma" == "" ]]; then
     nroNorma=0
  fi
  (( nroNorma++ ))
  nrosNorma["$1;$2;$3;$4"]="$nroNorma"
  contadoresModificados=true
  return $nroNorma

}

# Funcion principal

function main {
   
   validarEjecucionIniPro
   validacion=$?
   if [ $validacion -eq 0 ]; then 
      grabarLog "El ambiente no está inicializado." "ERR"
      grabarLog "No se ejecutará el programa ProPro." "ERR"
   else
      grabarLog "Inicio de ProPro." "INF"
      cantidadArchivos=`find $GRUPO$NOVEDIR$ACEPDIR -type f | wc -l`
      grabarLog "Cantidad de archivos a procesar: $cantidadArchivos" "INF"
      MAESTROGESTIONES="$GRUPO$MAEDIR/gestiones.mae"
      gestiones=""
      while read line || [[ -n "$line" ]]; do 
          gestiones+=$(echo $line | cut -d ";" -f1) 
          gestiones+=" "
      done < $MAESTROGESTIONES
      axgfile="$GRUPO$MAEDIR/tab/axg.tab"
      declare -A nrosNorma
      declare -A datosNrosNorma
      while read line || [[ -n "$line" ]]; do 
          clave=$(echo "$line" | cut -d ";" -f2)";"
          clave+=$(echo "$line" | cut -d ";" -f3)";"
          clave+=$(echo "$line" | cut -d ";" -f4)";"
          clave+=$(echo "$line" | cut -d ";" -f5)

          datos=$(echo "$line" | cut -d ";" -f1)";"
	  datos+=$(echo "$line" | cut -d ";" -f6)";"
	  datos+=$(echo "$line" | cut -d ";" -f7)";"
	  datos+=$(echo "$line" | cut -d ";" -f8)

          nro=$(echo "$line" | cut -d ";" -f6)
	  nrosNorma["$clave"]="$nro"
	  datosNrosNorma["$clave"]="$datos"
      done < $axgfile
      contadoresModificados=false
      cantidadArchivosProcesados=0
      cantidadArchivosRechazados=0
      for gestion in ${gestiones[*]}; do
          if [ `ls $GRUPO$NOVEDIR$ACEPDIR | grep -xc $gestion` != 0 ]; then
             if [ `ls $GRUPO$NOVEDIR$ACEPDIR/$gestion | cut -d"_" -f1 | grep -c $gestion` != 0 ]; then #Hay al menos un arch de la gestion
    		fechasordenadas=$(ls $GRUPO$NOVEDIR$ACEPDIR/$gestion | cut -d"_" -f5 | sort -k1.7 -k1.4 -k1.1)
   		for fecha in $fechasordenadas; do
        		for archivo in `ls $GRUPO$NOVEDIR$ACEPDIR/$gestion | grep $fecha`; do
                  		grabarLog "Archivo a procesar: $archivo" "INF"
                  		verificarDuplicado "$archivo" "$GRUPO$NOVEDIR$PROCDIR/proc"
                  		if [ $? == 0 ]; then   #Si esta duplicado
                   			grabarLog "Se rechaza el archivo por estar DUPLICADO." "WAR"
                    			./Mover.sh "$GRUPO$NOVEDIR$ACEPDIR/$gestion/$archivo" "$GRUPO$NOVEDIR$RECHDIR" "ProPro"
					(( cantidadArchivosRechazados++ ))
                 		 else
                      			norma=$(echo $archivo | cut -d "_" -f 2)
                      			emisor=$(echo $archivo | cut -d "_" -f 3)
                      			verificarNormaEmisor $norma $emisor
                      			if [ $? == 0 ]; then   #La combinacion COD_NORMA/COD_EMISOR no se encuentra en la tabla nxe.tab
                        		    grabarLog "Se rechaza el archivo. Emisor no habilitado en este tipo de norma." "WAR"
                        		    ./Mover.sh "$GRUPO$NOVEDIR$ACEPDIR/$gestion/$archivo" "$GRUPO$NOVEDIR$RECHDIR" "ProPro"
					    (( cantidadArchivosRechazados++ ))
                      			else
                         		    procesarArchivo "$archivo" "$gestion" 
					    mkdir -p "$GRUPO$NOVEDIR$PROCDIR/proc"
					    ./Mover.sh "$GRUPO$NOVEDIR$ACEPDIR/$gestion/$archivo" "$GRUPO$NOVEDIR$PROCDIR/proc" "ProPro"
					    (( cantidadArchivosProcesados++ ))
                      			fi
                  		fi
        		done
          	done
       	     fi
          fi
      done
      if [ true = $contadoresModificados ]; then
	 chmod 666 $GRUPO$MAEDIR/tab/axg.tab
	 grabarLog "Tabla de contadores preservada antes de su modificación en MAEDIR/tab/ant" "INF"
         mkdir -p "$GRUPO$MAEDIR/tab/ant/"
	 ./Mover.sh "$GRUPO$MAEDIR/tab/axg.tab" "$GRUPO$MAEDIR/tab/ant" "ProPro"
	 guardarNuevaTablaAXG
	 chmod 444 $GRUPO$MAEDIR/tab/ant/axg.tab
	 chmod 444 $GRUPO$MAEDIR/tab/axg.tab
      fi
      grabarLog "Cantidad de archivos a procesar: $cantidadArchivos" "INF"
      grabarLog "Cantidad de archivos procesados: $cantidadArchivosProcesados" "INF"
      grabarLog "Cantidad de archivos rechazados: $cantidadArchivosRechazados" "INF"
   fi 

}

main
