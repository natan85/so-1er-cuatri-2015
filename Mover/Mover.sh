# *******************************************************************
# *******************************************************************
# Sistemas Operativos - 1er cuat 2015
# Grupo 8 - Trabajo Practico H
# *******************************************************************
# Uso: ./Mover.sh <archivo> <destino> <comando>
# *******************************************************************
# Los tres parametros son cadenas de caracteres entre comillas dobles.
# <archivo> (obligatorio): path del archivo a mover
# <destino> (obligatorio): path del directorio de destino
# <comando> (obligatorio): nombre del comando que lo invoca
# *******************************************************************
# Nota: el ultimo parametro, que es opcional en el documento, lo
# hice obligatorio para nuestro TP (previa consulta al ayudante).
# Parece que asi funciona de modo mas coherente.
# *******************************************************************
# *******************************************************************
# Ejemplos de uso:
# ./Mover.sh "../NOVEDIR/archivo1.txt" "../RECHDIR" "ProPro"
# ./Mover.sh "../NOVEDIR/archivo2.pdf" "../ACEPDIR" "RecPro"
# ./Mover.sh "../NOVEDIR/archivo3.bin" "../PROCDIR" "InsPro"
# *******************************************************************
# *******************************************************************

#!/bin/bash

# ***************************************************
# Definiciones
# ***************************************************

# ubicacion relativa esperada del archivo de configuracion
CONFIG="../CONFDIR/InsPro.conf"

# ***************************************************
# Verificaciones
# ***************************************************

# verificar existencia archivo configuracion
if ! [ -e $CONFIG ]; 
then
	echo "[Glog] Error: el archivo de configuracion no existe"
	exit 1
fi

# obtener valores de configuracion
GRUPO=`grep '^GRUPO=' $CONFIG | sed 's/^GRUPO=\([^=]*\).*/\1/'`
DUPDIR=`grep '^DUPDIR=' $CONFIG | sed 's/^DUPDIR=\([^=]*\).*/\1/'`

# verificar valores de configuracion obtenidos
if [ -z $GRUPO ] || [ -z $DUPDIR ];
then
	echo "[Mover] Error en parametros de configuracion"
	exit 1
fi

# verificar la cantidad de parametros recibidos
if [ $# -lt 2 ]
then
	echo "[Mover] Error en cantidad de parametros recibidos"
	exit 1
fi

# obtener los valores de los parametros
archivo=$1
destino=$2

# si no existe el parametro opcional, se usa "Mover"
if [ $# -ge 3 ]
then
	comando=$3
else	
	comando="Mover"
fi

# ***************************************************

# verificar el archivo a mover
if [ ! -e "$archivo" ]
then
	./Glog.sh "$comando"  "Mover: El archivo a $archivo no existe" "ERR"
	echo "[Mover] Error: el archivo $archivo no existe"
	exit 1
fi

# verificar el directorio de destino
if [ ! -d "$destino" ]
then
	./Glog.sh "$comando"  "Mover: El directorio $destino no existe" "ERR"
	echo "[Mover] Error: el directorio $destino no existe"
	exit 1
fi

# verificar si el directorio de origen es igual al directorio de destino
origen="${archivo%/*}"
if [ "$origen" == "$destino" ]
then
	./Glog.sh "$comando" "Mover: Directorios de origen y destino son iguales" "ERR"
	echo "[Mover] Error: los directorios de origen y destino son iguales"
	exit 1
fi

# verificar si ya existe el archivo en el directorio destino,
# y en caso de existir moverlo al directorio de duplicados

nombre="${archivo##*/}"        # nombre del archivo (sin el path)
duplicados="$GRUPO/$DUPDIR"    # path del directorio de duplicados

if [ -e "$destino/$nombre" ]
then	
	# obtiene el ultimo numero asignado a los archivos con igual nombre	
	numero=$(ls -1 "$duplicados" | grep "^$nombre\.[0-9]*$" | sed 's/.*\.\([0-9]*\)$/\1/' | sort -g | tail -n 1)

	# genera el siguiente numero
	if [ -z $numero ]
	then
		numero=1
	else
		numero=$(($numero+1))
	fi

	# nombre del nuevo archivo numerado
	numerado="$nombre.$numero"
	
	# mover el archivo numerado al directorio de duplicados
	mv -f "$destino/$nombre" "$duplicados/$numerado"
	
	# escribir en el log del comando que llamo, y mostrar por pantalla
	./Glog.sh "$comando" "Archivo $numerado movido al directorio $DUPDIR" "INFO"
	echo "[Mover] Archivo $numerado movido al directorio $DUPDIR"
fi

# mover el archivo al directorio destino
mv -f "$archivo" "$destino/$nombre"

# escribir en el log del comando que llamo, y mostrar por pantalla
destino="${destino##*/}"
./Glog.sh "$comando" "Archivo $nombre movido al directorio $destino" "INFO"
echo "[Mover] Archivo $nombre movido al directorio $destino"

exit 0
