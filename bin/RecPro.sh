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

ciclo=0

while true
do
	let ciclo=ciclo+1
	./glog "RecPro.sh" "ciclo numero : $ciclo" INFO
	#Escribir el numero de ciclo en el LOG
	#Validar los archivos en el directorio de novedades
	#Si corresponde disparar ProPro
	sleep $intervalo
done
