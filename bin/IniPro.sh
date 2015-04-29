#!/bin/bash

#===========================================================
#
# ARCHIVO: IniPro.sh
#
# DESCRIPCION: Prepara el entorno de ejecución del TP
# 
# AUTOR: Solotun, Roberto. 
# PADRON: 85557
#
#===========================================================

# Llama al log para grabar
# $1 = mensaje
# $2 = tipo (INF WAR ERR)

function grabarLog {

   ./Glog.sh "IniPro" "$1" "$2"

}

# Verifica que las variables de ambiente este seteadas

function chequearVariables {

   for var in ${variables[*]}
     do
       res=`env | grep $var | cut -d"=" -f 2`

       if [ -z "$res" ]; then

         #echo -e "Falta la variable de ambiente $var, agregando..."

         setVariablesDeConfiguracion $var

         #echo -e "Variable $var ahora esta agregada"

       #else
         #echo -e "La variable de ambiente $var=$res existe"
       fi      
   done
   #echo -e 
}

# Lee las variables de Config del archivo InsPro.conf

function setVariablesDeConfiguracion {
    
    export $1=`grep "$1" "$CONFDIR/$confFile" | cut -d"=" -f 2`
}

# Chequea que existan los scripts en la carpeta BINDIR, 
# y tengan los permisos de lectura, escritura y ejecucion 
# seteados,sino los setea.

function chequearComandos {

 for i in ${comandos[*]}
   do
     if [ -f $BINDIR/$i ]; then
          #echo -e "El comando $i existe"
 
          if ! [ -x $BINDIR/$i ]; then 
            #echo -e "y tiene permisos de ejecucion"
          #else 
            chmod 777 $BINDIR/$i
            #echo -e "`ls -l $BINDIR/$i`"
          fi
         
     else
        #echo -e "El comando $i no existe" 
        grabarLog "El comando $i no existe." "ERR"
     fi
   done  
   #echo -e 
}

# Chequea que existan los maestros en la carpeta MAEDIR, 
# y tengan los permisos de lectura seteados,sino los setea.

function chequearMaestros {

 for i in ${maestros[*]}
   do
     if [ -f $MAEDIR/$i ]; then
          #echo -e "El archivo maestro $i existe"
 
          if ! ([ -r $MAEDIR/$i ] && ! [ -w $MAEDIR/$i ]) ; then
            #echo -e "y tiene permisos de lectura, pero no escritura"
          #else 
            chmod 444 $MAEDIR/$i
            #echo -e `ls -l $MAEDIR/$i`
          fi
         
     else
        #echo -e "El archivo maestro $i no existe" 
        grabarLog "El maestro $i no existe." "ERR"
     fi
   done  
   #echo -e 
}

# Chequea que existan las tablas en la carpeta MAEDIR/tab, 
# y tengan los permisos de lectura seteados,sino los setea.

function chequearTablas {

 for i in ${tablas[*]}
   do
     if [ -f $MAEDIR/tab/$i ]; then
          #echo -e "La tabla $i existe"
 
          if ! ([ -r $MAEDIR/tab/$i ] && ! [ -w $MAEDIR/tab/$i ]); then 
            #echo -e "y tiene permisos de lectura, pero no escritura"
          #else 
            chmod 444 $MAEDIR/tab/$i
            #echo -e `ls -l $MAEDIR/tab/$i`
          fi
         
     else
        #echo -e "La tabla $i no existe" 
        grabarLog "La tabla $i no existe." "ERR"
     fi
   done  
   #echo -e 
}

# Chequea que la carpeta donde se encuentran los comandos, este incluido en la variable PATH,
# para su correcta ejecucion, sino lo setea

function chequearPaths {
   
   ejec=`echo $PATH | grep $BINDIR`

  if [ -z "$ejec" ]; then

    #echo -e "No esta el path de ejecutables, agregando..."
    
    export PATH=$PATH:$BINDIR
    
    #echo -e "Agregado\n"

  #else

    #echo -e "El path de ejecutables esta seteado"
    
  fi 
  #echo -e
}

# Chequea si el proceso RecPro ya esta corriendo

function chequearRecPro {

 resultado=`ps ax | grep -v $$ | grep -v "grep" | grep "RecPro.sh"`

 if [ -z "$resultado" ]; then
   return 0
 else
   return 1
 fi
}

# Pregunta si se desea iniciar el comando RecPro, y actua segun la respuesta. 

function lanzarRecPro {
 
  echo "“Desea efectuar la activación de RecPro?” Si – No"
  read resp

  while [ "$resp" != "Si" ]
   do
     if [ "$resp" == "No" ]; then
       return 1
     fi

     echo "Ingrese una respuesta valida"
     read resp

   done
  return 0
}

# Muestra el mensaje de finalizacion de Inicializacion

function mostrarMensajeInstalacionFinalizada {

	CONFDIR="$GRUPO""conf"
	dirconf=`ls $CONFDIR`
	dirbin=`ls $BINDIR`
	dirmae=`ls -R $MAEDIR`
	dirlog=`ls $LOGDIR`

	procssid=$(ps ax | grep -v $$ | grep -v "grep" | grep "RecPro" | sed 's-\(^ *\)\([0-9]*\)\(.*$\)-\2-g')

	mensaje="
TP SO7508 Primer Cuatrimestre 2015. Tema H Copyright (c) Grupo 04.

Directorio de Configuración: $CONFDIR

Archivos: 
$dirconf


Directorio de Ejecutables: $BINDIR

Archivos: 
$dirbin


Directorio de Maestros y Tablas: $MAEDIR

Archivos: 
$dirmae


Directorio de recepción de documentos para protocolización: $NOVEDIR

Directorio de Archivos Aceptados: $ACEPDIR

Directorio de Archivos Rechazados: $RECHDIR

Directorio de Archivos Protocolizados: $PROCDIR

Directorio para informes y estadísticas: $INFODIR

Nombre para el repositorio de duplicados: $DUPCDIR

Directorio para Archivos de Log: $LOGDIR

Archivos: 
$dirlog


Estado del Sistema: INICIALIZADO

Demonio corriendo bajo el no.: <$procssid> "

	grabarLog "$mensaje" "INF"
	echo "$mensaje"

}

#Funcion principal

function main {

   error=false
   variables=(GRUPO BINDIR MAEDIR NOVEDIR ACEPDIR RECHDIR PROCDIR INFODIR DUPDIR LOGDIR LOGSIZE)
   maestros=(emisores.mae normas.mae gestiones.mae)
   comandos=(Start.sh Stop.sh Mover.sh Glog.sh InsPro.sh IniPro.sh RecPro.sh ProPro.sh InfPro.pl)
   tablas=(nxe.tab axg.tab)
   CONFDIR=../conf
   confFile=InsPro.conf
   if [ "true" == "`env | grep INICIALIZADO | cut -d"=" -f 2`" ]
   then
      echo -e "Ambiente ya inicializado, si quiere reiniciar termine su sesión e ingrese nuevamente."
      grabarLog "Ambiente ya inicializado, si quiere reiniciar termine su sesión e ingrese nuevamente." "INF"
   else
      echo -e "Comenzando a inicializar el ambiente."
      chequearVariables
      chequearComandos
      chequearPaths
      chequearMaestros
      chequearTablas

      lanzarRecPro
      if [ $? == 1 ]; then
	msj="\n-Usted ha elegido no arrancar RecPro, \npara hacerlo manualmente debe hacerlo de la siguiente manera: \nUso: ./Start.sh RecPro.sh\n"
	echo -e $msj
	grabarLog "$msj" "INF"
      else
	chequearRecPro
	if [ $? == 0 ]; then
	   Start.sh "RecPro.sh"
	   msj="\n-Usted ha elegido arrancar RecPro, \npara frenarlo manualmente debe hacerlo de la siguiente manera: \nUso: ./Stop.sh RecPro.sh\n"
	   echo -e $msj
	   procssid=$(ps ax | grep -v $$ | grep -v "grep" | grep "RecPro" | sed 's-\(^ *\)\([0-9]*\)\(.*$\)-\2-g')
	   echo -e "proc: $procssid"
	   grabarLog "proc: $procssid" "INF"
	else
	   msj="\n-RecPro ya iniciado, \npara frenarlo manualmente debe hacerlo de la siguiente manera: \nUso: ./Stop.sh RecPro.sh\n"
	   echo -e $msj
	   grabarLog "RecPro ya iniciado" "ERR"
	   procssid=$(ps ax | grep -v $$ | grep -v "grep" | grep "RecPro" | sed 's-\(^ *\)\([0-9]*\)\(.*$\)-\2-g')
	   echo -e "proc: $procssid"
	   grabarLog "RecPro.sh proc: $procssid" "ERR"
	fi
      fi
      export INICIALIZADO="true"
      mostrarMensajeInstalacionFinalizada
   fi

}

main
