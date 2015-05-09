#!/bin/bash

# *******************************************************************
# *******************************************************************
# Sistemas Operativos - 1er cuat 2015
# Grupo 8 - Trabajo Practico H
# *******************************************************************
# Uso: Glog.sh <comando> <mensaje> [codigo]
# *******************************************************************
# Los tres parametros son cadenas de caracteres.
# comando (obligatorio): nombre del comando que escribe en su log
# mensaje (obligatorio): texto del mensaje a escribir en el log
# codigo (opcional)    : alguno de los siguientes codigos
# INFO (Informativo)
# WAR (Warning/Aviso)
# ERR (Error)
# *******************************************************************
# *******************************************************************
# Ejemplos:
# Glog.sh "IniPro" "Directorio de archivos aceptados: $ACEPDIR" "INFO"
# Glog.sh "RecPro" "El archivo no es un archivo de texto" "ERR"
# Glog.sh "ProPro" "Se rechaza el archivo por estar duplicado" "WAR"
# *******************************************************************
# *******************************************************************

# *******************************************************************
# Definiciones
# *******************************************************************

# usuario del sistema
USUARIO="$USER"

# cantidad de lineas a conservar al recortar logs
LINEAS=30

# codigo por default (cuando no se recibe parametro codigo)
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

# verificar cantidad de parametros recibidos
if [ $# -lt 2 ] || [ $# -gt 3 ]
then
	echo "[Glog] Error en cantidad de parametros recibidos"
	exit 1
fi

# eliminar la extension del parametro comando (si venia incluida)
comando=`echo $1 | sed 's/\(.*\)\..*/\1/'`

# verificar si el comando es correcto
if ! [[ $comando =~ ^(IniPro|RecPro|ProPro|Mover)$ ]]; 
then
	echo "[Glog] Comando recibido desconocido"
	exit 1
fi

# verificar si el mensaje esta vacio
if [ -z "$2" ]
then
	echo "[Glog] Mensaje recibido esta vacío"
	mensaje="xxxx mensaje vacio xxx"
else
	mensaje=$2
fi

# verificar si se recibió codigo, y si es correcto
if [ $# -eq 3 ] && [[ $3 =~ ^(INFO|WAR|ERR)$ ]]
then
	codigo=$3		
else
	codigo=$CODIGO
fi

# directorio del archivo de log
dir=$GRUPO/$LOGDIR/$comando

# verificar existencia directorio de log, o crearlo
if [ ! -d $dir ]; 
then
	mkdir -p $dir
	echo "[Glog] Fue creado el directorio $dir"
fi

# ***************************************************
# Escribir en el log correspondiente al comando
# ***************************************************

# datos a escribir
fecha=`date +"%d-%m-%Y %H:%M:%S"`
usuario=$USUARIO

# archivo donde escribir
archivo=$dir/$comando".log"

# escribir en el log
echo "$fecha-$usuario-$comando-$codigo-$mensaje" >> "$archivo"

# ************************************************************
# Recortar archivo de log si es necesario (excepto IniPro.log)
# ************************************************************

# obtener tamanio del archivo
tamanio=$(stat -c %s "$archivo")

# recortar archivo si excedio el tamanio maximo
if [ $tamanio -gt $LOGSIZE ] && [ $comando != "IniPro" ];
then
	# copiar las utimas lineas en un archivo temporal
	cat "$archivo" | tail -n $LINEAS > "$archivo.tmp";
	
	# copiar el archivo temporal sobre el original
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

#****************************************************

exit 0
