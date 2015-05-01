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
#GRUPO=/home/pc/Escritorio/TPSO/Git/sisop-4h
#MAEDIR=maestros
#NOVEDIR=20115-1C-Datos/
#ACEPDIR=bin/aceptados
#RECHDIR=bin/rechazados
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
		echo "Moviendo a rechazados por formato"
		./Glog.sh "RecPro.sh" "Rechazado por formato invalido" INFO
		#escribir log
	done
}

# Valida que sean archivos de texto , los que hay en el directorio $NOVEDADES
# NO FUNCIONA 
function validar_tipo_archivos (){
	for archivo in $(ls -1 "$NOVEDADES");do
		if [ $(file "$NOVEDADES/$archivo" | grep -c "ASCII text") != 1 ];then
			./Mover.sh "$NOVEDADES/$archivo" "$RECHAZADOS"
			#Escribir log
		fi
	done
}


function validar_fecha (){
	#Obtengo fecha inicial y final , de la gestion
	fechaInicial=$(grep "^$gestion;.*;.*;.*;.*$" "$GESTIONES" | cut -d ";" -f 2 | sed s-"/"--g)
	fechaFinal=$(grep "^$gestion;.*;.*;.*;.*$" "$GESTIONES" | cut -d ";" -f 3 | sed s-"/"--g)
	fechaValidar=$fecha
	#Corto en dia,mes y año cada una de las fechas
	di=$(echo $fechaInicial | cut -d "/" -f 1)
	df=$(echo $fechaFinal | cut -d "/" -f 1)
	d3=$(echo $fechaValidar | cut -d "-" -f 1)
	mi=$(echo $fechaInicial | cut -d "/" -f 2)
	mf=$(echo $fechaFinal | cut -d "/" -f 2)
	m3=$(echo $fechaValidar | cut -d "-" -f 2)
	ai=$(echo $fechaInicial | cut -d "/" -f 3)
	af=$(echo $fechaFinal | cut -d "/" -f 3)
	a3=$(echo $fechaValidar | cut -d "-" -f 3)
	#Invierto el orden de las fechas para poder compararlas (año/mes/dia)
	fechaInicial="$ai$mi$di"
	fechaFinal="$af$mf$df"
	fechaValidar="$a3$m3$d3"
	if [[ "$fechaInicial" > "$fechaValidar" ]]; then
		#Antes de la fecha inicial
		return 1
	fi
	if [[ "$fechaFinal" < "$fechaValidar" ]]; then
		#Despues de la fecha final
		return 1
	fi	
	return 0
}



ciclo=0

while true
do
	let ciclo=ciclo+1
	./Glog.sh "RecPro.sh" "ciclo numero : $ciclo" INFO
	#Escribir el numero de ciclo en el LOG
	#Validar los archivos en el directorio de novedades
	hay_archivos
	if [ $cantidad_archivos -gt 0 ];then
		#Validacion de los nombres
		#validar_tipo_archivos
		validar_formato_nombre
		#Validaciones de cada campo
		listaArchivos=$(ls -1 $NOVEDADES)
		for archivo in $listaArchivos ; do
			gestion=$(echo $archivo | cut -d "_" -f 1)
			norma=$(echo $archivo | cut -d "_" -f 2)
			emisor=$(echo $archivo | cut -d "_" -f 3)
			fecha=$(echo $archivo | cut -d "_" -f 5)
			if [ $(grep -c "^$gestion;.*;.*;.*;.*$" "$GESTIONES") -eq 0 ];then
				./Mover.sh "$NOVEDADES/$archivo" "RECHAZADOS"
				./Glog.sh "RecPro.sh" "$archivo rechazados gestion invalida" INFO
				#Loggear	
			elif [ $(grep -c "^$norma;.*;.*$" "$NORMAS") -eq 0 ];then
				./Mover.sh "$NOVEDADES/$archivo" "RECHAZADOS"
				./Glog.sh "RecPro.sh" "$archivo rechazados cod_norma invalido" INFO
				#Loggear
			elif [ $(grep -c "^$emisor;.*;.*;.*$" "$EMISORES") -eq 0 ];then
				./Mover.sh "$NOVEDADES/$archivo" "RECHAZADOS"
				./Glog.sh "RecPro.sh" "$archivo rechazados cod_emisor invalido" INFO
				#Loguear
			else 
				validar_fecha
				if [ $? = 1 ];then
					./Mover.sh "$NOVEDADES/$archivo" "$RECHAZADOS"
					./Glog.sh "RecPro.sh" "$archivo rechazado fecha invalida" INFO
				else
					mkdir -p "$ACEPTADOS/$gestion"
					./Mover.sh "$NOVEDADES/$archivo" "$ACEPTADOS/$gestion"
					./Glog.sh "RecPro.sh" "$archivo aceptados" INFO
				fi
			fi
		done

	else 
		#Ir a directorio de ACEPTADOS
		#Invocar a ProPro
		ciclo=$ciclo	
	fi

	sleep $intervalo
done

