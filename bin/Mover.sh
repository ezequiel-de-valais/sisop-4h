#!/bin/bash

# Parametro 1 : Archivo a mover
# Parametro 2 : Directorio de destino del parametro 1
# Parametro 3 : Comando que lo invoca

# Valores de retorno
#	0: Operacion exitosa
#	1: Error de invocacion
#	2: Archivo o directorio inexistente
#	3: Directorio origen y destino iguales

archivo="$1"
directorio="$2"
comando="$3"
cantidad_parametros="$#"
dir_archivo="${archivo%/*}"
archivo_a_mover="${1##*/}"

function verificar_parametros() {
	if [ $cantidad_parametros -gt 3 ] || [ $cantidad_parametros -lt 2 ]; then
		# Llamar al logging de ezequiel
		exit 1
	fi
}

function verificar_directorios() {
	#Verifica existencia del archivo de entrada
	if [ ! -f $archivo ]; then
		#Llamar al logging
		exit 2	
	fi
	
	#Verifica existencia del directorio de destino
	if [ ! -d $directorio ]; then
		#Llamar al logging
		exit 2
	fi
	
}

function son_iguales() {
	if [ $dir_archivo == $directorio ]; then
		#Llamar al logging 
		exit 3
	fi
}


function mover_archivo () {
	#Veo si el archivo ya existe en el directorio de destino
	if [ -f "$directorio/$archivo_a_mover" ]; then
		if [ ! -d "$directorio/duplicados" ]; then
			#Creo el directorio de duplicados
			mkdir "$directorio/duplicados"
		fi
		nnn=$(ls "$directorio/duplicados" | grep "^$archivo_a_mover.[0-9]\{1,3\}" | sort -r | sed s/$archivo_a_mover.// | head -n 1)
		#Si no hay duplicados
		if [ "$nnn" == "" ]; then
			nnn=0
		fi

		nnn=$( echo $nnn + 1 | bc -l )
		mv "$archivo" "$directorio/duplicados/$archivo_a_mover.$nnn"
		#Llamar al logging
		exit 0
	else 
		mv "$archivo" "$directorio"
		#Llamar al logging
		exit 0
	fi
}



# Mover 

verificar_parametros
verificar_directorios
son_iguales
mover_archivo

