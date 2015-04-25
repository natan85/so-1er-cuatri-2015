# *******************************************************************
# *******************************************************************
# Sistemas Operativos - 1er cuat 2015
# Grupo 8 - Trabajo Practico H
# *******************************************************************
# Uso: ./Glog.sh <comando> <mensaje> [codigo]
# *******************************************************************
# Los tres parametros son cadenas de caracteres entre comillas dobles.
# <comando> (obligatorio): nombre del comando que escribe en su log
# <mensaje> (obligatotio): texto del mensaje a escribir en el log
# [codigo] (opcional): alguno de los siguientes codigos:
# INFO (Informativo)
# WAR (Warning/Aviso)
# ERR (Error)
# *******************************************************************
# *******************************************************************
# Ejemplos de uso:
# ./Glog.sh "RecPro" "Nuevos archivos recibidos" "INFO"
# ./Glog.sh "IniPro" "El sistema se inicializo parcialmente" "WAR"
# ./Glog.sh "ProPro" "Error en codigo de protocolizacion" "ERR"
# *******************************************************************
# *******************************************************************

#!/bin/bash

# *******************************************************************
# Definiciones
# *******************************************************************

# usuario del sistema en FIUBA
USUARIO="alumnos"

# cantidad de lineas a conservar al recortar logs
LINEAS=10

# codigo por default (cuando no se recibe codigo)
CODIGO="INFO"

# ubicacion relativa esperada del archivo de configuracion
CONFIG="../CONFDIR/InsPro.conf"

# *******************************************************************
# Verificaciones
# *******************************************************************

# verificar existencia archivo configuracion
if ! [ -e $CONFIG ]; 
then
	echo "[Glog] Error: el archivo de configuracion no existe"
	exit 1
fi

# obtener valores de configuracion
GRUPO=`grep '^GRUPO=' $CONFIG | sed 's/^GRUPO=\([^=]*\).*/\1/'`
LOGDIR=`grep '^LOGDIR=' $CONFIG | sed 's/^LOGDIR=\([^=]*\).*/\1/'`
LOGSIZE=`grep '^LOGSIZE=' $CONFIG | sed 's/^LOGSIZE=\([^=]*\).*/\1/'`

# verificar valores de configuracion obtenidos
if [ -z $GRUPO ] || [ -z $LOGDIR ] || [ -z $LOGSIZE ];
then
	echo "[Glog] Error en valores de configuracion"
	exit 1
fi

# verificar cantidad de parametros recibidos
if [ $# -lt 2 ];
then
	echo "[Glog] Error en cantidad de parametros recibidos"
	exit 1
fi

# verificar si hay codigo recibido
if [ $# -ge 3 ];
then
	if [ $3 != "INFO" ] && [ $3 != "WAR" ] && [ $3 != "ERR" ];
	then
		echo "[Glog] Error en codigo recibido"
		exit 1
	else
		CODIGO=$3
	fi
fi

# directorio del archivo de log
DIR=$GRUPO/$LOGDIR/$1

# verificar existencia directorio de log, o crearlo
if ! [ -d $DIR ]; 
then
	mkdir $DIR
	echo "[Glog] Fue creado el directorio $DIR"
fi

# ***************************************************
# Escribir en el log
# ***************************************************

# datos a escribir
fecha=`date +"%d-%m-%Y %H:%M:%S"`
usuario=$USUARIO
comando=$1
codigo=$CODIGO
mensaje=$2

# donde escribir
nombre="$1.log"
archivo=$DIR/$nombre

# escribir en el log
echo "$fecha-$usuario-$comando-$codigo-$mensaje" >> "$archivo"

# ***************************************************
# Recortar archivo de log si es necesario
# ***************************************************

# obtener tamanio archivo
tamanio=$(stat -c %s "$archivo")

# recortar archivo si excedio el tamanio maximo
if [ $tamanio -gt $LOGSIZE ];
then
	# copiar las utimas lineas en un archivo temporal
	cat "$archivo" | tail -n $LINEAS > "$archivo.tmp";
	
	# mover el archivo temporal sobre el original
	mv -f "$archivo.tmp" "$archivo"
	
	# datos para escribir en el log
	fecha=`date +"%d-%m-%Y %H:%M:%S"`
	usuario=$USUARIO
	comando="Glog"	
	codigo="WAR"
	mensaje="Archivo log excedido, se recorto"	
	
	# escribir en archivo de log    	
	echo "$fecha-$usuario-$comando-$codigo-$mensaje" >> "$archivo"
	
	# mostrar por pantalla	 
	echo "[Glog] Archivo $nombre excedido, se recorto"
fi

exit 0
