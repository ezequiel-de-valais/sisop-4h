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

   Glog.sh "IniPro" "$1" "$2"

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
    
    value=$(grep "$1" "$CONFDIR/$confFile" | cut -d"=" -f 2)
    export $1="$value"
    echo -e "$value"
}

# Chequea que existan los scripts en la carpeta BINDIR, 
# y tengan los permisos de lectura, escritura y ejecucion 
# seteados,sino los setea.

function chequearComandos {

 for i in ${comandos[*]}
   do
     if [ -f "$GRUPO$BINDIR/$i" ]; then
          #echo -e "El comando $i existe"
 
          if ! [ -x "$GRUPO$BINDIR/$i" ]; then 
            #echo -e "y tiene permisos de ejecucion"
          #else 
            chmod 777 "$GRUPO$BINDIR/$i"
            #echo -e "`ls -l $BINDIR/$i`"
          fi
         
     else
        #echo -e "El comando $i no existe" 
        grabarLog "El comando $GRUPO$BINDIR/$i no existe." "ERR"
        error=true
     fi
   done  
   #echo -e 
}

# Chequea que existan los maestros en la carpeta MAEDIR, 
# y tengan los permisos de lectura seteados,sino los setea.

function chequearMaestros {

 for i in ${maestros[*]}
   do
     if [ -f "$GRUPO$MAEDIR/$i" ]; then
          #echo -e "El archivo maestro $i existe"
 
          if ! ([ -r "$GRUPO$MAEDIR/$i" ] && ! [ -w "$GRUPO$MAEDIR/$i" ]) ; then
            #echo -e "y tiene permisos de lectura, pero no escritura"
          #else 
            chmod 444 "$GRUPO$MAEDIR/$i"
            #echo -e `ls -l $MAEDIR/$i`
          fi
         
     else
        #echo -e "El archivo maestro $i no existe" 
        grabarLog "El maestro $GRUPO$MAEDIR/$i no existe." "ERR"
        error=true
     fi
   done  
   #echo -e 
}

# Chequea que existan las tablas en la carpeta MAEDIR/tab, 
# y tengan los permisos de lectura seteados,sino los setea.

function chequearTablas {

 for i in ${tablas[*]}
   do
     if [ -f "$GRUPO$MAEDIR/tab/$i" ]; then
          #echo -e "La tabla $i existe"
 
          if ! ([ -r "$GRUPO$MAEDIR/tab/$i" ] && ! [ -w "$GRUPO$MAEDIR/tab/$i" ]); then 
            #echo -e "y tiene permisos de lectura, pero no escritura"
          #else 
            chmod 444 "$GRUPO$MAEDIR/tab/$i"
            #echo -e `ls -l $MAEDIR/tab/$i`
          fi
         
     else
        #echo -e "La tabla $i no existe" 
        grabarLog "La tabla $GRUPO$MAEDIR/tab/$i no existe." "ERR"
        error=true
     fi
   done  
   #echo -e 
}

# Chequea que la carpeta donde se encuentran los comandos, este incluido en la variable PATH,
# para su correcta ejecucion, sino lo setea

function chequearPaths {
   
   ejec=`echo "$PATH" | grep "$GRUPO$BINDIR"`

  if [ -z "$ejec" ]; then

    #echo -e "No esta el path de ejecutables, agregando..."
    
    export PATH="$PATH:$GRUPO$BINDIR"
    
    #echo -e "Agregado\n"

  #else

    #echo -e "El path de ejecutables esta seteado"
    
  fi 
  #echo -e
}

# Chequea si el proceso RecPro ya esta corriendo

function chequearRecPro {

 resultado=`ps ax | grep -v $$ | grep -v "grep" | grep -v "gedit" | grep "RecPro.sh"`

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

  while [ "${resp,,}" != "si" -a "${resp,,}" != "s" ]
   do
     if [ "${resp,,}" == "no" -o "${resp,,}" == "n" ]; then
       return 1
     fi

     echo "Ingrese una respuesta valida"
     read resp

   done
  return 0
}

# Muestra el mensaje de finalizacion de Inicializacion

function mostrarMensajeInstalacionFinalizada {

	#CONFDIR="${GRUPO}conf"
	dirconf=`ls "$CONFDIR" | tr "\n" " "`
	dirbin=`ls "$GRUPO$BINDIR" | tr "\n" " "`
	dirmae=`ls -R "$GRUPO$MAEDIR" | tr "\n" " "`
	dirlog=`ls "$GRUPO$LOGDIR" | tr "\n" " "`

        mensaje="Directorio de Configuración: $CONFDIR"
  	grabarLog "$mensaje" "INF"
	echo -e "$mensaje"

        mensaje="Archivos: $dirconf"
  	grabarLog "$mensaje" "INF"
	echo -e "$mensaje\n"

        mensaje="Directorio de Ejecutables: $GRUPO$BINDIR"
  	grabarLog "$mensaje" "INF"
	echo -e "$mensaje"

        mensaje="Archivos: $dirbin"
  	grabarLog "$mensaje" "INF"
	echo -e "$mensaje\n"

        mensaje="Directorio de Maestros y Tablas: $GRUPO$MAEDIR"
  	grabarLog "$mensaje" "INF"
	echo -e "$mensaje"

        mensaje="Archivos: $dirmae"
  	grabarLog "$mensaje" "INF"
	echo -e "$mensaje\n"

        mensaje="Directorio de recepción de documentos para protocolización: $GRUPO$NOVEDIR"
  	grabarLog "$mensaje" "INF"
	echo -e "$mensaje\n"

        mensaje="Directorio de Archivos Aceptados: $GRUPO$ACEPDIR"
  	grabarLog "$mensaje" "INF"
	echo -e "$mensaje\n"

        mensaje="Directorio de Archivos Rechazados: $GRUPO$RECHDIR"
  	grabarLog "$mensaje" "INF"
	echo -e "$mensaje\n"

        mensaje="Directorio de Archivos Protocolizados: $GRUPO$PROCDIR"
  	grabarLog "$mensaje" "INF"
	echo -e "$mensaje\n"

        mensaje="Directorio para informes y estadísticas: $GRUPO$INFODIR"
  	grabarLog "$mensaje" "INF"
	echo -e "$mensaje\n"

        mensaje="Nombre para el repositorio de duplicados: $GRUPO$DUPDIR"
  	grabarLog "$mensaje" "INF"
	echo -e "$mensaje\n"

        mensaje="Directorio para Archivos de Log: $GRUPO$LOGDIR"
  	grabarLog "$mensaje" "INF"
	echo -e "$mensaje"

        mensaje="Archivos: $dirlog"
  	grabarLog "$mensaje" "INF"
	echo -e "$mensaje\n"

        mensaje="Estado del Sistema: INICIALIZADO"
  	grabarLog "$mensaje" "INF"
	echo -e "$mensaje\n"

}

# Setea el CONFDIR

function setCONFDIR {

   CONFDIR="${PWD}/conf"
   confdirInvalido=true
   while [ "true" == "$confdirInvalido" ]
   do
      if [ ! -f "$CONFDIR/$confFile" ]; then
	 old="$CONFDIR"
         CONFDIR=""
         cantSeparadores=$(grep -o "/" <<< "$old" | wc -l)
         for (( c=2; c < $cantSeparadores; c++ ))
	 do
   	     aux=$(echo "$old" | cut -d "/" -f$c)
	     CONFDIR="$CONFDIR/$aux"
 	 done
         CONFDIR="$CONFDIR/conf"
      else
	 confdirInvalido=false
      fi
   done
   export CONFDIR="$CONFDIR"
}

# Funcion principal

function main {

   error=false
   variables=(GRUPO BINDIR MAEDIR NOVEDIR ACEPDIR RECHDIR PROCDIR INFODIR DUPDIR LOGDIR LOGSIZE)
   maestros=(emisores.mae normas.mae gestiones.mae)
   comandos=(Start.sh Stop.sh Mover.sh Glog.sh IniPro.sh RecPro.sh ProPro.sh InfPro.pl)
   tablas=(nxe.tab axg.tab)
   confFile=InsPro.conf
   setCONFDIR
   if [ "true" == "`env | grep INICIALIZADO | cut -d"=" -f 2`" ]
   then
      echo -e "Ambiente ya inicializado, si quiere reiniciar termine su sesión e ingrese nuevamente."
      grabarLog "Ambiente ya inicializado, si quiere reiniciar termine su sesión e ingrese nuevamente." "WAR"
   else
      echo -e "Comenzando a inicializar el ambiente.\n"
      chequearVariables
      chequearComandos
      chequearPaths
      chequearMaestros
      chequearTablas

      if [ false == $error ]; then
         mostrarMensajeInstalacionFinalizada
         lanzarRecPro
         if [ $? == 1 ]; then
	   msj="-Usted ha elegido no arrancar RecPro, para hacerlo manualmente debe hacerlo de la siguiente manera: Uso: Start.sh RecPro.sh"
	   echo -e $msj
	   grabarLog "Se ha elegido no arrancar RecPro" "INF"
         else
	   chequearRecPro
	   if [ $? == 0 ]; then
	      Start.sh "RecPro.sh"
	      msj="-Usted ha elegido arrancar RecPro, para frenarlo manualmente debe hacerlo de la siguiente manera: Uso: Stop.sh RecPro.sh"
	      echo -e $msj
	      procssid=$(ps -ax | grep -v $$ | grep -v "grep" | grep -v "gedit" | grep "RecPro.sh" | sed 's-\(^ *\)\([0-9]*\)\(.*$\)-\2-g')
	      echo -e "proc: $procssid"
	      grabarLog "proc: $procssid" "INF"
	   else
	      msj="-RecPro ya iniciado, para frenarlo manualmente debe hacerlo de la siguiente manera: Uso: Stop.sh RecPro.sh"
	      echo -e $msj
	      grabarLog "RecPro ya iniciado" "ERR"
	      procssid=$(ps -ax | grep -v $$ | grep -v "grep" | grep -v "gedit" | grep "RecPro.sh" | sed 's-\(^ *\)\([0-9]*\)\(.*$\)-\2-g')
	      echo -e "proc: $procssid"
	      grabarLog "RecPro.sh proc: $procssid" "ERR"
	   fi
         fi	 
	 export INICIALIZADO="true"
      else
         msj="Error en la inicialización del ambiente. Revise el log para mayor información."
	 echo -e $msj
	 export INICIALIZADO="false"
      fi
   fi

}

main
