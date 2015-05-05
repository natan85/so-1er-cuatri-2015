# *******************************************************************
# *******************************************************************
# Sistemas Operativos - 1er cuat 2015
# Grupo 8 - Trabajo Practico H
# *******************************************************************
# Uso: 
# ./Mover.sh <archivo_a_mover> <directorio_de_destino> <comando_que_lo_usa>
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
# ./Mover.sh "$archivo" "$rechdir" "ProPro"
# ./Mover.sh "$archivo" "$acepdir" "ProPro"
# *******************************************************************
# *******************************************************************

#!/bin/bash

# ***************************************************
# Definiciones
# ***************************************************

# comando por default (si no hay tercer parametro)
COMANDO="Mover"

# ***************************************************
# Verificaciones
# ***************************************************

# verificar variables de ambiente
if [ ! -n "${GRUPO+1}" ] || [ ! -n "${DUPDIR+1}" ]
then
	echo "[Mover] Error en variables de ambiente"
	exit 1
fi

# eliminar el path de DUPDIR (si venia incluido)
DUPDIR="${DUPDIR##*/}" 

# verificar la cantidad de parametros recibidos
if [ $# -lt 2 ]
then
	echo "[Mover] Error en cantidad de parametros recibidos"
	exit 1
fi

# obtener los valores de los parametros
archivo=$1
destino=$2

if [ $# -ge 3 ]
then
	comando=$3
else	
	comando=$COMANDO
fi

# ***************************************************

# verificar el archivo a mover
if [ ! -e "$archivo" ]
then
	./Glog.sh "$comando"  "El archivo $archivo no existe" "ERR"
	echo "[Mover] Error: el archivo $archivo no existe"
	exit 1
fi

# verificar el directorio de destino
if [ ! -d "$destino" ]
then
	./Glog.sh "$comando"  "El directorio $destino no existe" "ERR"
	echo "[Mover] Error: el directorio $destino no existe"
	exit 1
fi

# verificar si el directorio de origen es igual al directorio de destino

origen="${archivo%/*}"   # path del archivo (sin el nombre)

if [ "$origen" == "$destino" ]
then
	./Glog.sh "$comando" "Directorios de origen y destino son iguales" "ERR"
	echo "[Mover] Error: los directorios de origen y destino son iguales"
	exit 1
fi

# ***************************************************

# verificar si ya existe el archivo en el directorio destino,
# y en caso de existir moverlo al directorio de duplicados

nombre="${archivo##*/}"        # nombre del archivo (sin el path)
duplicados="$GRUPO/$DUPDIR"    # path del directorio de duplicados

# si no existe el directorio para duplicados, lo crea
if ! [ -d $duplicados ]
then
	mkdir $duplicados
	./Glog.sh "$comando" "Fue creado el directorio $duplicados" "WAR"
	echo "[Mover] Fue creado el directorio $duplicados"
fi

# verificar el archivo
if [ -e $destino/$nombre ]
then	
	# obtiene el ultimo numero asignado a los archivos con igual nombre	
	numero=$(ls -1 "$duplicados" | grep "^$nombre\.[0-9]*$" | sed 's/.*\.\([0-9]*\)$/\1/' | sort -g | tail -n 1)

	# genera el numero sucesivo
	if [ -z $numero ]
	then
		numero=1
	else
		numero=$(($numero+1))
	fi

	# nombre del nuevo archivo numerado
	numerado=$nombre.$numero
	
	# mover el archivo numerado al directorio de duplicados
	mv -f $destino/$nombre $duplicados/$numerado
	
	# escribir en el log y mostrar por pantalla
	./Glog.sh "$comando" "Archivo duplicado $numerado movido a $DUPDIR" "INFO"
	echo "[Mover] Archivo duplicado $numerado movido a $DUPDIR"
fi

# ***************************************************

# mover el archivo
mv -f "$archivo" "$destino/$nombre"

# escribir en el log
destino="${destino##*/}"  # nombre del directorio (sin el path)
./Glog.sh "$comando" "Archivo $nombre movido al directorio $destino" "INFO"

# mostrar por pantalla
echo "[Mover] Archivo $nombre movido al directorio $destino"

exit 0
