#!/bin/bash
# Objetivos:
# . Detener procesos
# Restricciones:
# . No se puede arrancar un proceso que no existe WTF
# . No se puede arrancar un proceso si no se inicializo el ambiente

# Parametro1 : Nombre del proceso

Proceso=$1
# Obtener PID del proceso,
# para verificar que no esta corriendo
# Obtengo procesos con ps ax , uso grep para quedarme con los que no son $$ (este proceso),
# que no sean grep , que no sea Start.sh y que matchee cn el nombre del proceso
ProcesosCorriendo=$(ps ax | grep -v $$ | grep -v "grep" | grep -v "Start.sh" | grep $Proceso)
# Del filtro anterior , me quedo con la primer linea , y de la primer linea saco los primeros 4 bytes 
PIDproceso=$(echo $ProcesosCorriendo | head -n 1 | head -c 4)
if [ "$PIDproceso" == "" ]; then
	echo "proceso no existe"
	#Escribir en el log que el archivo se esta ejecutando
else
	echo "$PIDproceso"
	# Detengo el proceso
	kill "$PIDproceso"
fi

 
echo "" | head -n 1 | head -c 4