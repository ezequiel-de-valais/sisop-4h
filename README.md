#################################################################################
FIUBA - 75.08 - Sistemas Operativos - Primer Cuatrimestre 2015
GRUPO N° 4
# Aller, Juan Maria
# Arroyo, Hernan
# de Valais, Ezequiel
# Grillo, Ezequiel
# Nery, Francisco
# Solotun, Roberto 
#################################################################################
Pasos a seguir en la instalación y ejecución del programa SisProH
#################################################################################
1- Insertar el dispositivo de almacenamiento con el contenido del tp (pen drive, cd, etc).
2- Ubicarse en el directorio donde se desea instalar el programa.
3- Copiar el archivo Grupo4H.tar.gz en el directorio mencionado anteriormente.
4- Descomprimir el archivo Grupo4H.tar.gz. 
5. Se creará un nuevo comprimido, el cual descomprimiremos de la misma forma que en el paso anterior.
6. Luego de esto, se habrá creado la carpeta Grupo4H, la cual es la base del programa.
7. Para instalar el programa, desde la consola ir a la ruta donde se creo la carpeta Grupo4H y ejecutar los siguientes comandos:

$ cd Grupo4H
$ sh InsPro.sh

8. Luego de haber seguido los pasos indicados en el instalador, si este finalizó correctamente, se habrán creado varias carpetas útiles . P
ara el funcionamiento correcto del programa (no se debe cambiar su nombre en ningun momento, de surgir algún problema se recomienda
 reinstalar el programa y comenzar de nuevo).

9. Dirigirse a la carpeta definida para los ejecutables (por defecto /bin):

$ cd bin

10. Correr con punto para que las variables queden en el ambiente actual a IniPro.sh:

$ . IniPro.sh

11. En este momento, el usuario podrá elegir entre ejecutar el demonio RecPro.sh o no.   De decidir no ejecutarlo, podrá hacerlo luego manualmente mediante el siguiente comando:

$ Start.sh RecPro.sh

12. Si el usuario quiere detener la ejecución de este demonio, deberá escribir:

$ Stop.sh RecPro.sh

13. NOVEDADES Y REPORTING




####################################

Notas del instalador:

Luego de correr el comando InsPro.sh , se creará el archivo de configuración InsPro.conf en la carpeta conf. Esto se hace inmediatamente antes de ingresar los valores de las variables, guardando las variables GRUPO y CONF. A medida que se ingresan las variables, estas también son guardadas en el archivo. Esto se hace en caso de que se interrumpa la instalación (ej. por corte de luz) y se pueda resumir desde la útima variable ingresada.
Al resumir la instalación, dado que no se terminó de ingresar las variables previamente, se tomará la instalación como INCOMPLETA. Se indicarán cuales son las variables que ya fueron ingresadas, cuales son las que faltan y se preguntará si se quiere resumir la instalación.   
