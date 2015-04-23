# ************************************************ #
# Sistemas Operativos - 1er cuat 2015
# Grupo 8 - Trabajo Practico H
# ************************************************ #
# Uso: Glog.sh <comando> <mensaje> [codigo]
# ************************************************ #
# comando: nombre del comando que escribe en su log
# mensaje: texto del mensaje a escribir en el log
# codigo opcional: 
# INFO (Informativo)
# WAR (Warning)
# ERR (Error)
# ************************************************ #

#!/bin/bash

# ***************************************************
# Definiciones
# ***************************************************

# usuario del sistema
USUARIO="alumnos"

# ubicacion esperada del archivo de configuracion
CONF=../CONFDIR/InsPro.conf

# cantidad de lineas a conservar al recortar logs
LINEAS=10

# codigo por default (usado cuando no hay codigo)
CODIGO="INFO"

# ***************************************************
# Verificaciones
# ***************************************************

# verificar existencia archivo configuracion
if ! [ -e $CONF ]; 
then
	echo "[Glog] El archivo de configuracion no existe"
	exit 1
fi

# directorio base del usuario
#BASE=$(grep $USUARIO /etc/passwd | cut -f6 -d":")

# obtener valores de configuracion
GRUPO=`grep '^GRUPO=' $CONF | sed 's/^GRUPO=\([^=]*\).*/\1/'`
LOGDIR=`grep '^LOGDIR=' $CONF | sed 's/^LOGDIR=\([^=]*\).*/\1/'`
LOGSIZE=`grep '^LOGSIZE=' $CONF | sed 's/^LOGSIZE=\([^=]*\).*/\1/'`

# directorio de archivos de log
DIR=$HOME/$GRUPO/$LOGDIR/

# verificar existencia directorio de logs, o crearlo
if ! [ -d $DIR ]; 
then
	echo "[Glog] El directorio para logs no existe, se creara"
	mkdir -p $DIR
fi

# verificar cantidad de parametros recibidos
if [ $# -lt 2 ];
then
	echo "[Glog] Error en cantidad de parametros recibidos"
	exit 1
fi

# verificar el codigo opcional
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

# ***************************************************
# Escribir en el log
# ***************************************************

# datos a escribir
fecha=`date +"%d-%m-%Y %H:%M:%S"`
usuario=$USUARIO
comando=$1
mensaje=$2
codigo=$CODIGO

# lugar donde escribir
nombre="$1.log"
archivo=$DIR$nombre

# escribir en el log
echo "$fecha-$usuario-$comando-$mensaje-$codigo" >> "$archivo"

# ***************************************************
# Recortar archivo de log si es necesario
# ***************************************************

# obtener tamanio archivo
tamanio=$(stat -c%s "$archivo")

# recortar archivo si excedio el tamanio maximo
if [ $tamanio -gt $LOGSIZE ];
then
	cat "$archivo" | tail -n $LINEAS > "$archivo.tmp";
	mv -f "$archivo.tmp" "$archivo"	
	fecha=`date +"%d-%m-%Y %H:%M:%S"`;
	comando="Glog"	
	mensaje="Archivo log excedido, se recorto"
	codigo="INFO"	    	
	echo "$fecha-$usuario-$comando-$mensaje-$codigo" >> "$archivo"
	echo "$fecha -> Archivo $nombre excedido, se recorto"
fi

exit 0
