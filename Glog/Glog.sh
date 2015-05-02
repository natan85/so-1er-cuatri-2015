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
USUARIO="$USER"

# cantidad de lineas a conservar al recortar logs
LINEAS=10

# codigo por default (cuando no se recibe codigo)
CODIGO="INFO"

# *******************************************************************
# Verificaciones
# *******************************************************************

# verificar variables de ambiente
if [ ! -n "${GRUPO+1}" ] || [ ! -n "${LOGDIR+1}" ] || [ ! -n "${LOGSIZE+1}" ];
then
	echo "[Glog] Error en variables de ambiente"
	exit 1
fi

# eliminar el path de LOGDIR (si venia incluido)
LOGDIR="${LOGDIR##*/}"

# verificar parametros recibidos
if [ $# -lt 2 ];
then
	echo "[Glog] Error en cantidad de parametros recibidos"
	exit 1
fi

comando=`echo $1 | sed 's/\(.*\)\..*/\1/'`
mensaje=$2

# verificar si hay codigo recibido, y si es correcto
if [ $# -ge 3 ];
then
	if [ $3 != "INFO" ] && [ $3 != "WAR" ] && [ $3 != "ERR" ];
	then
		echo "[Glog] Error en codigo recibido, se reemplaza por INFO"
	else
		codigo=$3
	fi
fi

# directorio del archivo de log
DIR=$GRUPO/$LOGDIR/$comando

# verificar existencia directorio de log, o crearlo
if [ ! -d $DIR ]; 
then
	mkdir -p $DIR
	echo "[Glog] Fue creado el directorio $DIR"
fi

# ***************************************************
# Escribir en el log
# ***************************************************

# datos a escribir
fecha=`date +"%d-%m-%Y %H:%M:%S"`
usuario=$USUARIO

# archivo donde escribir
archivo=$DIR/$comando".log"

# escribir en el log
echo "$fecha-$usuario-$comando-$codigo-$mensaje" >> "$archivo"

# ***************************************************
# Recortar archivo de log si es necesario
# ***************************************************

# obtener tamanio del archivo
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
	mensaje="Archivo ${archivo##*/} excedido, se recorto"	
	
	# escribir en archivo de log    	
	echo "$fecha-$usuario-$comando-$codigo-$mensaje" >> "$archivo"
	
	# mostrar por pantalla
	echo "[Glog] Archivo ${archivo##*/} excedido, se recorto"
fi

exit 0
