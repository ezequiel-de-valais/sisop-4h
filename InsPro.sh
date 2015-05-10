#!/bin/bash
#TP SisProH - Grupo 4 - Tema H

#Variables para el config
GRUPO=$(pwd)/
CONFDIR="conf"
BINDIR=""
MAEDIR=""
NOVEDIR=""
DATASIZE=""
ACEPDIR=""
RECHDIR=""
PROCDIR=""
INFODIR=""
DUPDIR=""
LOGDIR=""
LOGSIZE=""


#Variables para el script
RUTA_CONFIG="$CONFDIR/InsPro.conf"
USER_NAME=`whoami`
COMANDOS="Glog.sh InfPro.pl IniPro.sh Mover.sh ProPro.sh RecPro.sh Start.sh Stop.sh"


#loguear mensajes de instalador

log() {
	mensaje=$1
	tipo=$2
	script="InsPro"	

	if [ "$tipo" = "" ]
	then
		tipo="INFO"
	fi
	
	bin/Glog.sh "$script" "$mensaje" "$tipo"
}
#####################
mostrarYLoguear(){
	echo "$1"
	log "$1" "$2"
}

#####################
existeArchivo() {
	# Archivo a chequear en 1er parametro
	if [ ! -e $1 ]
	then	
		return 1
	fi

	return 0
}

verificarArchivosNecesarios() {

bindir=bin
maedir=mae
falla=0

	# Verifico si esta el directorio bin
	if [ ! -d "$bindir" ]; then
		mostrarYLoguear "No existe el directorio '$bindir' con los archivos necesarios para instalar el programa." "ERR"
		falla=1	
	fi
	# Verifico si esta el directorio mae
	if [ ! -d "$maedir" ]; then
		mostrarYLoguear "No existe el directorio '$maedir' con los archivos necesarios para instalar el programa." "ERR"
		falla=1
	fi

	if [ $falla -eq 1 ]; then
		return 1	
	fi

	for comando in $COMANDOS
	do
	    	existeArchivo "$bindir/$comando"
		if [ $? -eq 1 ]; then
			mostrarYLoguear "Falta el archivo $comando en el directorio $bindir. No se puede instalar el programa." "ERR"
			falla=1
	    	fi
	done
	if [ $falla -eq 1 ]; then
		return 1	
	fi
return 0
}

#Chequeo que la computadora tenga Perl instalado
#return 0 : esta instalado
#return 1 : no esta instalado
#############################
existePerl() {
	if perl < /dev/null > /dev/null 2>&1
	then
		return 0
	else
		return 1
	fi
}
##############################
getVersionPerl() {
	PERL_VERSION=$(perl -v | grep 'v[0-9]' | sed 's/[^0-9]//g' | cut -c1)
	return $PERL_VERSION
}

#####################
#Retorna 1 si responde afirmativamente, 0 si no
preguntar(){
mensaje=$1
	mostrarYLoguear "$mensaje"	
	
	while true
	do
		read respuesta
		log "El usario ingresó: $respuesta"

		if [ "$respuesta" = "S" ] || [ "$respuesta" = "s" ]
		then
			return 1
		elif [ "$respuesta" = "N" ] || [ "$respuesta" = "n" ]
		then
		    	return 0
		else
			mostrarYLoguear "Por favor escriba S/s o N/n"
		fi
	done
}

########################
inicializarValoresDefault(){
	BINDIR_DEFAULT=bin
	MAEDIR_DEFAULT=mae
	NOVEDIR_DEFAULT=novedades
	DATASIZE_DEFAULT=100
	ACEPDIR_DEFAULT=a_protocolizar
	RECHDIR_DEFAULT=rechazados
	PROCDIR_DEFAULT=protocolizados
	INFODIR_DEFAULT=informes
	DUPDIR_DEFAULT=dup
	LOGDIR_DEFAULT=log
	LOGSIZE_DEFAULT=400
}

#return 0 = es valido
#return 1 = es invalido
#######################
nombreDirValido() {
    
	if [ "$1" = "" ]
	then
		return 0
	fi
	
	if [ "$1" == "conf" ] || [ "$1" == "pruebas" ]
	then
		"Los directorios 'conf' y 'pruebas' ya están siendo utilizados por el sistema, eliga otro directorio. "
		return 1
	fi
	dif=`echo $1 | sed 's,[^0-9a-zA-Z/ ],,g'`
	if [ "$1" = "$dif" ]
	then
		return 0
	fi
	return 1
}

########################
actualizarValor() {
	valor_viejo=$1
	valor_nuevo=$2
	if [ "$valor_viejo" = "BINDIR" ]; then
		BINDIR_DEFAULT=$valor_nuevo
	elif [ "$valor_viejo" = "MAEDIR" ]; then
		MAEDIR_DEFAULT=$valor_nuevo
	elif [ "$valor_viejo" = "NOVEDIR" ]; then
		NOVEDIR_DEFAULT=$valor_nuevo
	elif [ "$valor_viejo" = "ACEPDIR" ]; then
		ACEPDIR_DEFAULT=$valor_nuevo
	elif [ "$valor_viejo" = "RECHDIR" ]; then
		RECHDIR_DEFAULT=$valor_nuevo
	elif [ "$valor_viejo" = "PROCDIR" ]; then
		PROCDIR_DEFAULT=$valor_nuevo
	elif [ "$valor_viejo" = "INFODIR" ]; then
		INFODIR_DEFAULT=$valor_nuevo
	elif [ "$valor_viejo" = "DUPDIR" ]; then
		DUPDIR_DEFAULT=$valor_nuevo
	elif [ "$valor_viejo" = "LOGDIR" ]; then
		LOGDIR_DEFAULT=$valor_nuevo
	elif [ "$valor_viejo" = "LOGSIZE" ]; then
		LOGSIZE_DEFAULT=$valor_nuevo
	elif [ "$valor_viejo" = "DATASIZE" ]; then
		DATASIZE_DEFAULT=$valor_nuevo
	fi
}
#Si valor ya existe en el config actualizarlo
############################
escribirValorEnConfig(){
	clave=$1
	valor=$2
	if [ -f $RUTA_CONFIG ]
	then
		#leer el valor
		leer=`grep "$clave" $RUTA_CONFIG | cut -d '=' -f 2`
	else
		leer=""
	fi
	fecha="`date`"
	if [ "$leer" = "" ]
	then
		#Si variable no existe agregar
		echo "$clave=$valor=$USER_NAME=$fecha" >> $RUTA_CONFIG
	else
		#Si existe actualizo su valor
		TEMP=`sed "s,$clave=.*$,$clave=$valor=$USER_NAME=$fecha,g" $RUTA_CONFIG`
		#Reescribo config
		IFS='
'
		rm $RUTA_CONFIG
		for i in $TEMP
		do
			echo $i >> $RUTA_CONFIG
		done
		unset IFS
	fi
	return 0
}

########################
procesarDirectorio(){
	directorio=$1
	dir_default=$2
	mensaje=$3
	valor=`grep "$directorio" $RUTA_CONFIG | cut -f2 -d'='`
	if [ "$valor" = "" ] || [ "$forzar" = 1 ]
	then
		while true
		do
			mostrarYLoguear "$mensaje" 
			read valor
			nombreDirValido $valor
			if [ $? -eq 1 ]
			then
				mostrarYLoguear "El nombre ingresado es invalido. Solo puede contener letras y/o números y no puede ser 'conf' o 'pruebas' ya que estos son utlizados por el sitema." "WAR"
			continue
			elif [ "$valor" = "" ]
			then
				valor=$dir_default
				log "Se usará el valor por defecto" 
			else
				actualizarValor "$directorio" "$valor"
				log "El usario ingreso: $valor"
			fi
			valor=$(echo "$valor" | sed 's, ,\ ,g')
			escribirValorEnConfig "$directorio" "$valor"
			break
		done
	fi
}

#return 0 = es numero
#return 1 = no es numero
#################################
esNumero() {

	if [ "$1" = "" ]
	then
		return 0
	fi

	dif=$(echo $1 | sed 's,[^0-9],,g')
	if [ "$dif" = "$1" ]
	then
		return 0
	fi
	return 1
}

#######################
procesarDataSize() {
	valor=`grep "DATASIZE" $RUTA_CONFIG | cut -f2 -d'='`
	if [ "$valor" = "" ] || [ "$forzar" = 1 ]
	then
		while true
		do
			ESPACIO_EN_DISCO=`df -Phm / | tail -1 | tr -s ' ' | cut -d ' ' -f4`
			mostrarYLoguear "Defina espacio mínimo libre para el arribo de novedades en MBytes ($DATASIZE_DEFAULT MB):"

			read DATASIZE_TEMP
			esNumero $DATASIZE_TEMP
			if [ $? -eq 1 ]
			then
				mostrarYLoguear "Por favor ingrese un valor numerico." "WAR"
				continue
			elif [ "$DATASIZE_TEMP" != "" ]
			then
			
				log "El usario ingreso: $DATASIZE_TEMP"
				if [ $ESPACIO_EN_DISCO -lt $DATASIZE_TEMP ]
				then
					mostrarYLoguear "Insuficiente espacio en disco:
	Espacio disponible: $ESPACIO_EN_DISCO MB.
	Espacio requerido: $DATASIZE_TEMP MB.
	Cancele la instalación o inténtelo nuevamente."
					continue
				else
					DATASIZE=$DATASIZE_TEMP
					actualizarValor "DATASIZE" $DATASIZE
				fi
				break
			else
				DATASIZE=$DATASIZE_DEFAULT
				log "Se usará el valor por defecto" 
				break
			fi
		done
	fi

	escribirValorEnConfig "DATASIZE" "$DATASIZE"
}

###########################
procesarTamanoLog() {
	CLAVE="LOGSIZE"	
	
	valor=`grep "$CLAVE" $RUTA_CONFIG | cut -f2 -d'='`
	if [ "$valor" = "" ] || [ "$forzar" = 1 ]
	then
		while true
		do
			mostrarYLoguear "Defina el tamaño máximo para cada archivo de log en KBytes ($LOGSIZE_DEFAULT):"
			read LOGSIZE_TEMP
			esNumero "$LOGSIZE_TEMP"
			if [ $? -eq 1 ]
			then
				mostrarYLoguear "Por favor ingrese un valor numerico" "WAR"
				continue
			elif [ "$LOGSIZE_TEMP" != "" ]
			then
				VALOR=$LOGSIZE_TEMP
				log "El usario ingreso: $VALOR"
				actualizarValor $CLAVE $VALOR
				break
			else
				VALOR=$LOGSIZE_DEFAULT
				log "Se usará el valor por defecto: $VALOR"
				break
			fi
		done
	fi
	escribirValorEnConfig $CLAVE $VALOR
}



#########################
procesarTodo(){
	procesarDirectorio "BINDIR" "$BINDIR_DEFAULT" "Defina el directorio de instalación de los ejecutables (/$BINDIR_DEFAULT):"
	procesarDirectorio "MAEDIR" "$MAEDIR_DEFAULT" "Defina directorio para maestros y tablas (/$MAEDIR_DEFAULT):"
	procesarDirectorio "NOVEDIR" "$NOVEDIR_DEFAULT" "Defina el directorio de recepción de documentos para protocolización (/$NOVEDIR_DEFAULT):"
	procesarDataSize
	procesarDirectorio "ACEPDIR" "$ACEPDIR_DEFAULT" "Defina el directorio de grabación de las novedades aceptadas (/$ACEPDIR_DEFAULT):"
	procesarDirectorio "RECHDIR" "$RECHDIR_DEFAULT" "Defina el directorio de grabacion de archivos rechazados (/$RECHDIR_DEFAULT):"
	procesarDirectorio "PROCDIR" "$PROCDIR_DEFAULT" "Defina el directorio de grabación de los documentos protocolizados (/$PROCDIR_DEFAULT):"
	procesarDirectorio "INFODIR" "$INFODIR_DEFAULT" "Defina el directorio de grabación de los informes de salida (/$INFODIR_DEFAULT):"
	procesarDirectorio "DUPDIR" "$DUPDIR_DEFAULT" "Defina el directorio de grabación de los informes de salida (/$DUPDIR_DEFAULT):"
	procesarDirectorio "LOGDIR" "$LOGDIR_DEFAULT" "Defina el directorio de logs (/$LOGDIR_DEFAULT):"
	procesarTamanoLog  
}

#Si no existe el archivo, retorna 1
leerValoresConfig() {
	if [ -f $RUTA_CONFIG ]
	then
		GRUPO=`grep 'GRUPO' $RUTA_CONFIG | cut -f2 -d'='`
		CONFDIR=`grep 'CONFDIR' $RUTA_CONFIG | cut -f2 -d'='`
		BINDIR=`grep 'BINDIR' $RUTA_CONFIG | cut -f2 -d'='`
		MAEDIR=`grep 'MAEDIR' $RUTA_CONFIG | cut -f2 -d'='`
		NOVEDIR=`grep 'NOVEDIR' $RUTA_CONFIG | cut -f2 -d'='`
		ACEPDIR=`grep 'ACEPDIR' $RUTA_CONFIG | cut -f2 -d'='`
		RECHDIR=`grep 'RECHDIR' $RUTA_CONFIG | cut -f2 -d'='`		
		PROCDIR=`grep 'PROCDIR' $RUTA_CONFIG | cut -f2 -d'='`
		INFODIR=`grep 'INFODIR' $RUTA_CONFIG | cut -f2 -d'='`
		DUPDIR=`grep 'DUPDIR' $RUTA_CONFIG | cut -f2 -d'='`
		LOGDIR=`grep 'LOGDIR' $RUTA_CONFIG | cut -f2 -d'='`
		LOGEXT=`grep 'LOGEXT' $RUTA_CONFIG | cut -f2 -d'='`
		LOGSIZE=`grep 'LOGSIZE' $RUTA_CONFIG | cut -f2 -d'='`
		DATASIZE=`grep 'DATASIZE' $RUTA_CONFIG | cut -f2 -d'='`
		return 0
	else
		return 1
	fi
}

#Retorna 1 si no existe el directorio
####################
getArchivosEn() {
	if [ -d $1 ]
	then
		ARCHIVOS=`ls -l $1 | grep "^-" | grep "[^~]$" | sed 's/  */ /g' | cut -f9 -d ' '`
		return 0
	else
	return 1
	fi
}

####################
infoInstalacion() {

	mostrarYLoguear "TP SO7508 Primer Cuatrimestre 2015. Tema H Copyright © Grupo 4"
	mostrarYLoguear "Directorio de Configuracion: $CONFDIR"
	getArchivosEn $CONFDIR
	if [ $? -eq 0 ]
	then
		for archivo in $ARCHIVOS
		do
			mostrarYLoguear "	$archivo"
		done
	fi
	mostrarYLoguear "Directorio de Ejecutables: $BINDIR"
	getArchivosEn $BINDIR
	if [ $? -eq 0 ]
	then
		for archivo in $ARCHIVOS
		do
			mostrarYLoguear "	$archivo"
		done
	fi	
	mostrarYLoguear "Directorios Maestros y Tablas: $MAEDIR"
	getArchivosEn $MAEDIR
	if [ $? -eq 0 ]
	then
		for archivo in $ARCHIVOS
		do
			mostrarYLoguear "	$archivo"
		done
	fi
	mostrarYLoguear "Directorio de recepción de documentos para protocolización: $NOVEDIR"
	mostrarYLoguear "Espacio mínimo libre para arribos: $DATASIZE Mb"
	mostrarYLoguear "Directorio de Archivos Aceptados: $ACEPDIR"
	mostrarYLoguear "Directorio de Archivos Rechazados: $RECHDIR"
	mostrarYLoguear "Directorio de Archivos Protocolizados: $PROCDIR"
	mostrarYLoguear "Directorio para informes y estadísticas: $INFODIR"
	mostrarYLoguear "Nombre para el repositorio de duplicados: $DUPDIR"
	mostrarYLoguear "Directorio para Archivos de Log: $LOGDIR"
	if [ ! "$LOGDIR" = "" ]
	then	
		getArchivosEn $LOGDIR
		if [ $? -eq 0 ]
		then
			for archivo in $ARCHIVOS
			do
				mostrarYLoguear "	$archivo"
			done
		fi
	fi
	mostrarYLoguear "Tamaño máximo para los archivos de log del sistema: $LOGSIZE Kb"
}

crearDirectorios() {
	#Crear directorios en el caso que no existen
	mkdir -p "$GRUPO$BINDIR"
	mostrarYLoguear "$GRUPO$BINDIR ..."
	mkdir -p "$GRUPO$MAEDIR"
	mostrarYLoguear "$GRUPO$MAEDIR ..."
	mkdir -p "$GRUPO$MAEDIR"/tab
	mostrarYLoguear "$GRUPO$MAEDIR/tab ..."
	mkdir -p "$GRUPO$MAEDIR"/tab/ant
	mostrarYLoguear "$GRUPO$MAEDIR/tab/ant ..."
	mkdir -p "$GRUPO$NOVEDIR"
	mostrarYLoguear "$GRUPO$NOVEDIR ..."
	mkdir -p "$GRUPO$ACEPDIR"
	mostrarYLoguear "$GRUPO$ACEPDIR ..."
	mkdir -p "$GRUPO$RECHDIR"
	mostrarYLoguear "$GRUPO$RECHDIR ..."
	mkdir -p "$GRUPO$PROCDIR" 
	mostrarYLoguear "$GRUPO$PROCDIR ..."
	mkdir -p "$GRUPO$PROCDIR"/proc 
	mostrarYLoguear "$GRUPO$PROCDIR/proc ..."
	mkdir -p "$GRUPO$INFODIR"
	mostrarYLoguear "$GRUPO$INFODIR ..."
	mkdir -p "$GRUPO$LOGDIR"
	mostrarYLoguear "$GRUPO$LOGDIR ..."
}

#########################
inicializarInstalacion(){
	
	existePerl
	existe=$?
	getVersionPerl
	version=$?
	
	if [ $existe -eq 0 ] && [ $version -ge 5 ]
	then

		#Perl 5 o superior esta instalado
		forzar=0
		while true
		do		
			if [ $faltaInstalar -eq 0 ]; then
				escribirValorEnConfig "GRUPO" "$GRUPO"
				escribirValorEnConfig "CONFDIR" "$CONFDIR"			
				mostrarYLoguear "TP SO7508 Primer Cuatrimestre 2015. Tema H Copyright © Grupo 4. \nPerl Version: $version"
				procesarTodo
			fi
			clear
			faltaInstalar=0			
			leerValoresConfig
			infoInstalacion
			mostrarYLoguear "Estado de la instalacion: LISTA"
			echo ""
			preguntar "Inicia la instalacion? (S - N)"
			if [ $? -eq 1 ] #si
			then
				break
			fi
			clear
			forzar=1
		done
	
		preguntar "Iniciando Instalación. Esta Ud. seguro? (S - N)"
		if [ $? -eq 0 ] #no
		then
			MENSAJE_FINAL="Instalación cancelada por el usuario."
		else
		
			mostrarYLoguear "Creando Estructuras de directorio. . . ."

			leerValoresConfig
			crearDirectorios

			mostrarYLoguear "Instalando Archivos Maestros y Tablas"
			cp -Rf mae/* "$GRUPO$MAEDIR"/

			mostrarYLoguear "Instalando Programas y Funciones"
			cp -Rf bin/* "$GRUPO$BINDIR"/
			
			mostrarYLoguear "Actualizando la configuración del sistema"

			MENSAJE_FINAL="Instalación concluida exitosamente."
		fi
	else
	mostrarYLoguear "TP SO7508 Primer Cuatrimestre 2015. Tema H Copyright © Grupo 4. \n Para instalar el TP es necesario contar con Perl 5 o superior. Efectúe su instalación e inténtelo nuevamente.\n Proceso de Instalación Cancelado"
	fi
}

chequearFaltantes() {
	modulos_faltantes=""	
	if [ "$GRUPO" = "" ]
	then
		modulos_faltantes=$modulos_faltantes"GRUPO"
	fi
	if [ "$CONFDIR" = "" ]
	then
		modulos_faltantes=$modulos_faltantes" CONFDIR"
	fi
	if [ "$BINDIR" = "" ]
	then
		modulos_faltantes=$modulos_faltantes" BINDIR"
	fi
	if [ "$MAEDIR" = "" ]
	then
		modulos_faltantes=$modulos_faltantes" MAEDIR"
	fi 
	if [ "$NOVEDIR" = "" ]
	then
		modulos_faltantes=$modulos_faltantes" NOVEDIR"
	fi 
	if [ "$DATASIZE" = "" ]
	then
		modulos_faltantes=$modulos_faltantes" DATASIZE"
	fi 
	if [ "$ACEPDIR" = "" ]	
	then	
		modulos_faltantes=$modulos_faltantes" ACEPDIR"
	fi 
	if [ "$RECHDIR" = "" ]
	then
		modulos_faltantes=$modulos_faltantes" RECHDIR"
	fi
	if [ "$PROCDIR" = "" ]
	then
		modulos_faltantes=$modulos_faltantes" PROCDIR"
	fi  
	if [ "$INFODIR" = "" ]
	then
		modulos_faltantes=$modulos_faltantes" INFODIR"
	fi 
	if [ "$DUPDIR" = "" ]
	then
		modulos_faltantes=$modulos_faltantes" DUPDIR"
	fi 
	if [ "$LOGDIR" = "" ]
	then
		modulos_faltantes=$modulos_faltantes" LOGDIR"
	fi 
	if [ "$LOGSIZE" = "" ]
	then
		modulos_faltantes=$modulos_faltantes" LOGSIZE"
	fi 
}

obtenerValorVector(){
	vector=$1
	indice=$2
	VALOR_VECTOR=`echo $vector | cut -f $indice -d' '`
}

chequearInstalacion(){
	if [ ! -d $BINDIR ]; then
		faltaInstalar=1
		return
	fi
	if [ ! -d $MAEDIR ]; then
		faltaInstalar=1
		return
	fi
	if [ ! -d $MAEDIR/tab ]; then
		faltaInstalar=1
		return
	fi
	if [ ! -d $MAEDIR/tab/ant ]; then
		faltaInstalar=1
		return
	fi
	if [ ! -d $NOVEDIR ]; then
		faltaInstalar=1
		return
	fi
	if [ ! -d $ACEPDIR ]; then
		faltaInstalar=1
		return
	fi
	if [ ! -d $RECHDIR ]; then
		faltaInstalar=1
		return
	fi
	if [ ! -d $PROCDIR ]; then
		faltaInstalar=1
		return
	fi
	if [ ! -d $PROCDIR/proc ]; then
		faltaInstalar=1
		return
	fi
	if [ ! -d $INFODIR ]; then
		faltaInstalar=1
		return
	fi
	if [ ! -d $LOGDIR ]; then
		faltaInstalar=1
		return
	fi
}

#########################
#########################
#########################
#Inicio Script
clear
echo "Inicio de Ejecución de InsPro"
chmod 700 "bin/Glog.sh"

export GRUPO
#Me fijo que exista todo lo necesario para que el programa funcione
verificarArchivosNecesarios
if [ $? -eq 1 ]; then
	exit 1
fi
if [ ! -d $CONFDIR ]
then
	mkdir $CONFDIR
fi

#INICIALIZO LOG

mostrarYLoguear "Log de la instalación: /conf/InsPro.log"	
mostrarYLoguear "Directorio predefinido de Configuración: $CONFDIR"

inicializarValoresDefault
existeArchivo "$RUTA_CONFIG"
faltaInstalar=0
if [ $? -eq 1 ]
then
	#Si no existe, iniciar instalacion
	inicializarInstalacion
else
	#Si existe, comprobar que esta instalado completamente
	leerValoresConfig
	chequearFaltantes
	obtenerValorVector "$modulos_faltantes" "1"
	#Se definieron todos los directorios, falta ver si se crearon
	if [ "$VALOR_VECTOR" = "" ]
	then
		chequearInstalacion
		if [ $faltaInstalar -eq 1 ] 
		then
			inicializarInstalacion
		else		
			mostrarYLoguear "Estado de la instalación: Completa."
			echo ""
			mostrarYLoguear "Proceso de Instalación Cancelado."
		fi
	#Falta algo	
	else
		infoInstalacion		
		echo ""
		mostrarYLoguear "Componentes faltantes:" "ERR"
		for faltante in $modulos_faltantes
		do
			mostrarYLoguear "	$faltante" "ERR"
		done

		mostrarYLoguear "Estado de la instalación: Incompleta."
		preguntar "Desea completar la instalación? (S-N)"
		if [ $? -eq 0 ]
		then
			MENSAJE_FINAL="Instalacion abortada por el usuario."
			break
		else
			inicializarInstalacion
		fi
	fi 
fi

mostrarYLoguear "$MENSAJE_FINAL"
exit

