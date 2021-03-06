#!/bin/bash
# Objetivos:
# . Detener procesos

# Parametro1 : Nombre del proceso

Proceso=$1
# Obtener PID del proceso,
# para verificar que no esta corriendo
# Obtengo procesos con ps ax , uso grep para quedarme con los que no son $$ (este proceso),
# que no sean grep , que no sea Start.sh y que matchee cn el nombre del proceso

Command="Stop"
ProcesosCorriendo=$(ps ax | grep -v $$ | grep -v "grep" | grep -v "gedit" | grep -v "Stop.sh" | grep $Proceso)
# Del filtro anterior , me quedo con la primer linea , y de la primer linea saco los primeros 4 bytes 
PIDproceso=$(echo "$ProcesosCorriendo" | sed 's-\(^ *\)\([0-9]*\)\(.*$\)-\2-g')
if [ "$PIDproceso" == "" ]; then

	Glog.sh $Command "Proceso $Command no existe" WAR
else
	Glog.sh $Command "Deteniendo proceso $Command" INFO
	kill "$PIDproceso"
	#TODO: revisar proceso no existe
	#TODO: hacer while por si existe mas de un proceso con el nombre o algo asi
fi
 
