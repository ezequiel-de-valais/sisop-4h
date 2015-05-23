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
NOVEDADES="$GRUPO$NOVEDIR/"
EMISORES="$GRUPO$MAEDIR/emisores.mae"
NORMAS="$GRUPO$MAEDIR/normas.mae"
GESTIONES="$GRUPO$MAEDIR/gestiones.mae"
ACEPTADOS="$GRUPO$ACEPDIR/"
RECHAZADOS="$GRUPO$RECHDIR/"

#TODO:Rechazar los archivos inválidos
#• Si el archivo viene vacio, rechazarlo
#• Si el archivo no es un archivo común, de texto (si es una imagen, un comprimido, etc),
#rechazarlo


# Devuelve en la variable cantidad_archivos
# la cantidad en el directorio $NOVEDADES
function hay_archivos() {
	cantidad_archivos=$(ls -1 $NOVEDADES | wc -l)
	for archivo in $(ls -1 "$NOVEDADES"); do
		cant_lineas=$(wc -m "$NOVEDADES/$archivo")
		cant=$(echo "$cant_lineas" | cut -d " " -f 1)
		if [[ "$cant" = "0" ]];then
			Mover.sh "$NOVEDADES/$archivo" "$RECHAZADOS"
			Glog.sh "RecPro" "$archivo archivo vacio" INFO
			let cantidad_archivos=cantidad_archivos-1
		fi
	done
}

# Valida el formato de los nombres , moviendo los que no cumplen a rechazados
function validar_formato_nombre (){
	archivos_a_rechazados=$(ls -1 $NOVEDADES | grep -v "^.*_.*_.*_.*_.*$") 
	for archivo in $archivos_a_rechazados;do
		Mover.sh "$NOVEDADES/$archivo" "$RECHAZADOS"
		#echo "Moviendo a rechazados por formato"
		Glog.sh "RecPro" "$archivo rechazado por formato invalido" INFO
		#escribir log
	done
}

# Valida que sean archivos de texto , los que hay en el directorio $NOVEDADES
# NO FUNCIONA 
function validar_tipo_archivos (){
	for archivo in $(ls -1 "$NOVEDADES");do
		if [ $(file "$NOVEDADES/$archivo" | grep -c "text") = 0 ];then
			Mover.sh "$NOVEDADES/$archivo" "$RECHAZADOS"
			#Escribir log
			Glog.sh "RecPro" "$archivo no es de texto" INFO
		fi
	done
}


function validar_fecha (){
	#Obtengo fecha inicial y final , de la gestion
	fechaInicial=$(grep "^$gestion;.*;.*;.*;.*$" "$GESTIONES" | cut -d ";" -f 2 | sed s-"/"--g)
	fechaFinal=$(grep "^$gestion;.*;.*;.*;.*$" "$GESTIONES" | cut -d ";" -f 3 | sed s-"/"--g)
	fechaValidar=$fecha
	
	#Corto en dia,mes y año cada una de las fechas
	d3=$(echo $fechaValidar | cut -d "-" -f 1)
	m3=$(echo $fechaValidar | cut -d "-" -f 2)
	a3=$(echo $fechaValidar | cut -d "-" -f 3)
	
	di=$(echo $fechaInicial | cut -c1,2)
	mi=$(echo $fechaInicial | cut -c3,4)
	ai=$(echo $fechaInicial | cut -c5,6,7,8)

	#Invierto el orden de las fechas para poder compararlas (año/mes/dia)
	fechaInicial=$(date --date="$ai-$mi-$di" +"%Y%m%d" 2>&-)
	if [ "$?" = "1" ]; then
		Glog.sh "RecPro" "fecha invalida inicial de mae $ai-$mi-$di , formato incorrecto" WAR
		return 1;
	fi

	fechaValidar=$(date --date="$a3-$m3-$d3" +"%Y%m%d" 2>&-)
	if [ "$?" = "1" ]; then
		Glog.sh "RecPro" "fecha invalida en $archivo, formato incorrecto" WAR
		return 1;
	fi
	#echo "fechaInicial: $fechaInicial fechaFinal:$fechaFinal fechaValidar:$fechaValidar"

	if [[ "$fechaInicial" -gt "$fechaValidar" ]]; then
		Glog.sh "RecPro" "fecha invalida en $archivo, anterior a la gestion" WAR

		#Antes de la fecha inicial
		#echo "es menor"
		return 1
	fi

	if [[ "$fechaFinal" = "NULL" ]]; then
		fechaHoy=$(date  +"%Y%m%d")
		if [[ "$fechaHoy" -gt "$fechaValidar" ]]; then
			Glog.sh "RecPro" "nope, todo OK" INFO
			return 0
		fi
		Glog.sh "RecPro" "fecha invalida en $archivo, posterior al dia de hoy" WAR
		return 1
	fi

	
	df=$(echo $fechaFinal | cut -c1,2)
	mf=$(echo $fechaFinal | cut -c3,4)
	af=$(echo $fechaFinal | cut -c5,6,7,8)
	fechaFinal="$af$mf$df"
	
	if [[ "$fechaFinal" < "$fechaValidar" ]]; then
		Glog.sh "RecPro" "fecha invalida en $archivo, posterior a la gestion" WAR

		#Despues de la fecha final
		#echo "es major, $fechaFinal"		
		return 1
	fi	
	return 0
}



ciclo=0

while true
do
	let ciclo=ciclo+1
	Glog.sh "RecPro" "ciclo numero : $ciclo" INFO
	#Escribir el numero de ciclo en el LOG
	#Validar los archivos en el directorio de novedades
	hay_archivos
	if [ $cantidad_archivos -gt 0 ];then
		#Validacion de los nombres
		validar_tipo_archivos
		validar_formato_nombre
		#Validaciones de cada campo
		listaArchivos=$(ls -1 $NOVEDADES)
		for archivo in $listaArchivos ; do
			gestion=$(echo $archivo | cut -d "_" -f 1)
			norma=$(echo $archivo | cut -d "_" -f 2)
			emisor=$(echo $archivo | cut -d "_" -f 3)
			fecha=$(echo $archivo | cut -d "_" -f 5)
			if [ $(grep -c "^$gestion;.*;.*;.*;.*$" "$GESTIONES") -eq 0 ];then
				Mover.sh "$NOVEDADES/$archivo" "$RECHAZADOS"
				Glog.sh "RecPro" "$archivo rechazados gestion invalida" INFO
				#Loggear	
			elif [ $(grep -c "^$norma;.*;.*$" "$NORMAS") -eq 0 ];then
				Mover.sh "$NOVEDADES/$archivo" "$RECHAZADOS"
				Glog.sh "RecPro" "$archivo rechazados cod_norma invalido" INFO
				#Loggear
			elif [ $(grep -c "^$emisor;.*;.*;.*$" "$EMISORES") -eq 0 ];then
				Mover.sh "$NOVEDADES/$archivo" "$RECHAZADOS"
				Glog.sh "RecPro" "$archivo rechazados cod_emisor invalido" INFO
				#Loguear
			else 
				validar_fecha
				if [ $? = 1 ];then
					Mover.sh "$NOVEDADES/$archivo" "$RECHAZADOS"
					Glog.sh "RecPro" "$archivo rechazado fecha invalida" INFO
				else
					mkdir -p "$ACEPTADOS/$gestion"
					Mover.sh "$NOVEDADES/$archivo" "$ACEPTADOS/$gestion"
					Glog.sh "RecPro" "$archivo aceptados" INFO
				fi
			fi
		done

	else 
		#Ir a directorio de ACEPTADOS
		#Invocar a ProPro
		for subdirectorio in $(ls -1 "$ACEPTADOS");do
			cantidad=$(ls -1 "$ACEPTADOS/$subdirectorio"| wc -l)
			if [ $cantidad -gt 0 ];then
				ProcesosCorriendo=$(ps ax | grep -v $$ | grep -v "grep" | grep -v "RecPro.sh" | grep "ProPro.sh")
				PID=$(echo $ProcesosCorriendo | sed 's-\(^ *\)\([0-9]*\)\(.*$\)-\2-g')
				if [ "$PID" = "" ]; then
					Start.sh ProPro.sh
					ProcesosCorriendo=$(ps ax | grep -v $$ | grep -v "grep" | grep -v "RecPro.sh" | grep "ProPro.sh")
	                                PID=$(echo $ProcesosCorriendo | sed 's-\(^ *\)\([0-9]*\)\(.*$\)-\2-g')
				else
					Glog.sh "RecPro" "Invocacion de ProPro pospuesta para el siguiente ciclo" INFO
				
				fi
				Glog.sh "RecPro" "ProPro corriendo bajo el no.: <$PID>" INFO
				break
			fi
		done
			
	fi

	sleep $intervalo
done

