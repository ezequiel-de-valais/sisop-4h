#!/bin/bash
# Objetivos:
# . Detener procesos

# Parametro1 : Nombre del proceso

Proceso=$1
# Obtener PID del proceso,
# para verificar que no esta corriendo
# Obtengo procesos con ps ax , uso grep para quedarme con los que no son $$ (este proceso),
# que no sean grep , que no sea Start.sh y que matchee cn el nombre del proceso
ProcesosCorriendo=$(ps ax | grep -v $$ | grep -v "grep" | grep -v "Stop.sh" | grep $Proceso)
# Del filtro anterior , me quedo con la primer linea , y de la primer linea saco los primeros 4 bytes 
PIDproceso=$(echo "$ProcesosCorriendo" | head -n 1 | head -c 4)
if [ "$PIDproceso" == "" ]; then
	echo "proceso no existe"
	#Escribir en el log que el archivo se esta ejecutando
else
	# Detengo el proceso
	kill "$PIDproceso"
fi

 
