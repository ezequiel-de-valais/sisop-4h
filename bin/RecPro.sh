#!/bin/bash
# Demonio 
# Se dispara por Start
# Se detiene con Stop
# Graba en el log a traves de Glog
# Mueve archivos con Mover
# Puede invocar a ProPro
# Duerme 

# Tiempo que duerme
intervalo=10
GRUPO=/home/pc/Escritorio/TPSO/Git/sisop-4h
MAEDIR=20115-1C-Datos/maestros
NOVEDIR=20115-1C-Datos/
ACEPDIR=bin/aceptados
RECHDIR=bin/rechazados
NOVEDADES="$GRUPO/$NOVEDIR/"
EMISORES="$GRUPO/$MAEDIR/emisores.mae"
NORMAS="$GRUPO/$MAEDIR/normas.mae"
GESTIONES="$GRUPO/$MAEDIR/gestiones.mae"
ACEPTADOS="$GRUPO/$ACEPDIR/"
RECHAZADOS="$GRUPO/$RECHDIR/"

# Devuelve en la variable cantidad_archivos
# la cantidad en el directorio $NOVEDADES
function hay_archivos() {
	cantidad_archivos=$(ls -1 $NOVEDADES | wc -l)
}

# Valida el formato de los nombres , moviendo los que no cumplen a rechazados
function validar_formato_nombre (){
	archivos_a_rechazados=$(ls -1 $NOVEDADES | grep -v "^.*_.*_.*_.*_.*$") 
	for archivo in $archivos_a_rechazados;do
		./Mover.sh "$NOVEDADES/$archivo" "$RECHAZADOS"
		#escribir log
	done
}

# Valida que sean archivos de texto , los que hay en el directorio $NOVEDADES
function validar_tipo_archivos (){
	for archivo in $(ls -1 $NOVEDADES);do
		if [ ! -f $archivo ];then
			./Mover.sh "$NOVEDADES/$archivo" "$RECHAZADOS"
			#Escribir log
		fi
	done
}


ciclo=0

while true
do
	let ciclo=ciclo+1
	#./glog "RecPro.sh" "ciclo numero : $ciclo" INFO
	#Escribir el numero de ciclo en el LOG
	#Validar los archivos en el directorio de novedades
	hay_archivos
	if [ $cantidad_archivos -gt 0 ];then
		#Validacion de los nombres
		#validar_tipo_archivos
		validar_formato_nombre
	else 
		#Ir a directorio de ACEPTADOS
		#Invocar a ProPro
		ciclo=$ciclo	
	fi

	sleep $intervalo
done

