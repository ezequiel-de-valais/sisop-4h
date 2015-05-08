#!/bin/bash
# Objetivos:
# . Disparar procesos
# . Arranca el dominio , y se usa para que un comando invoque a otro
# Restricciones:
# . No se puede arrancar un proceso que ya esta corriendo
# . No se puede arrancar un proceso si no se inicializo el ambiente

# Parametro1 : Nombre del proceso

Proceso=$1
# Obtener PID del proceso,
# para verificar que no esta corriendo
# Obtengo procesos con ps ax , uso grep para quedarme con los que no son $$ (este proceso),
# que no sean grep , que no sea Start.sh y que matchee cn el nombre del proceso
ProcesosCorriendo=$(ps ax | grep -v $$ | grep -v "grep" | grep -v "Start.sh" | grep $Proceso)
# Del filtro anterior , me quedo con la primer linea , y de la primer linea saco los primeros 4 bytes 
PIDproceso=$(echo $ProcesosCorriendo | sed 's-\(^ *\)\([0-9]*\)\(.*$\)-\2-g')
if [ "$PIDproceso" == "" ]; then
	# Inicio el proceso
	bash $Proceso &
	Glog.sh "Start" "Inicio de Demonio" INFO
else
	Glog.sh "Start" "Demonio ya iniciado" WAR
fi

 
