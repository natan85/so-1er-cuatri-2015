#!/bin/bash

#
# Validaciones de argumentos
#

# Leer de variables de ambiente GRUPO/XXX cuando se tenga
grupo="home/bliberini/TP/so-1er-cuatri-2015"
acepdir=$grupo/"acepDirMock"
maedir=$grupo/"maeDirMock"
procdir=$grupo/"procDirMock"
rechdir=$grupo/"rechDirMock"
logdir=$grupo/"logDirMock"

cd "/"

if [ "$1" == "--help" ]; then
	cat "ProProHelp.txt"
	exit 1
fi

# Checkeo de archivos y tablas disponibles
if [ ! -d "$grupo" ]
then
	#Loggear cuando se tenga GLog	
	echo "No se encuentra el directorio $grupo"
	exit 2
fi

if [ ! -d "$acepdir" ]
then
	#Loggear cuando se tenga GLog	
	echo "No se encuentra el directorio $acepdir"
	exit 2
fi

if [ ! -d "$maedir" ]
then
	#Loggear cuando se tenga GLog	
	echo "No se encuentra el directorio $maedir"
	exit 2
fi

if [ ! -d "$procdir" ]
then
	#Loggear cuando se tenga GLog	
	echo "No se encuentra el directorio $procdir"
	exit 2
fi

if [ ! -d "$rechdir" ]
then
	#Loggear cuando se tenga GLog	
	echo "No se encuentra el directorio $rechdir"
	exit 2
fi

if [ ! -d "$logdir" ]
then
	#Loggear cuando se tenga GLog	
	echo "No se encuentra el directorio $logdir"
	exit 2
fi

# Verifica existencia de los archivos maestros y tablas, y permisos de lectura
if [ ! -f "$maedir/emisores.mae" ]
then
	#Loggear cuando se tenga GLog	
	echo "No se encuentra el archivo $maedir/emisores.mae"
	exit 2
else
	if [ ! -r "$maedir/emisores.mae" ]
	then
		#Loggear cuando se tenga GLog	
		echo "No se tienen permisos para leer $maedir/emisores.mae"
		exit 2
	fi
fi

if [ ! -f "$maedir/gestiones.mae" ]
then
	#Loggear cuando se tenga GLog	
	echo "No se encuentra el archivo $maedir/gestiones.mae"
	exit 2
else
	if [ ! -r "$maedir/gestiones.mae" ]
	then
		#Loggear cuando se tenga GLog	
		echo "No se tienen permisos para leer $maedir/gestiones.mae"
		exit 2
	fi
fi

if [ ! -f "$maedir/tab/axg.tab" ]
then
	#Loggear cuando se tenga GLog	
	echo "No se encuentra el archivo $maedir/tab/axg.tab"
	exit 2
else
	if [ ! -r "$maedir/tab/axg.tab" ]
	then
		#Loggear cuando se tenga GLog	
		echo "No se tienen permisos para leer $maedir/tab/axg.tab"
		exit 2
	fi
fi

if [ ! -f "$maedir/tab/nxe.tab" ]
then
	#Loggear cuando se tenga GLog	
	echo "No se encuentra el archivo $maedir/tab/nxe.tab"
	exit 2
else
	if [ ! -r "$maedir/tab/nxe.tab" ]
	then
		#Loggear cuando se tenga GLog	
		echo "No se tienen permisos para leer $maedir/tab/nxe.tab"
		exit 2
	fi
fi

if [ ! -n "$(ls $acepdir)" ]
then
		#Loggear cuando se tenga GLog	
		echo "No hay archivos para protocolizar en $acepdir"
		exit 3
fi	

#
# Fin Validaciones
#

#
# Inicio carga de tablas y maestros de consulta
#

normxemi=$(cat "$maedir/tab/nxe.tab")

#
# Fin carga de tablas
#

# Nota: pasar todos los "echo" a loggeo cuando se integre con GLog

archivos=()

# Búsqueda de archivos y ordenado por fecha
for posFile in $(find "$acepdir" -printf "%p\n" | grep -v "~" | sort -t'_' -k5.7,5.10 -k5.4,5.5 -k5.1,5.2)
do
	if [ -f $posFile ]; then
		archivos+=($posFile)	
	fi
done
cantArchivos=$(printf '%s\n' "${archivos[@]}" | wc -l)

#
# Inicio de loggeo
#

echo -e "Inicio de ProPro\n"
echo "Cantidad de archivos a procesar: $cantArchivos"

#
# Fin inicio de loggeo
#

#
# Inicio de procesado
#

for archivo in ${archivos[@]}
do
	filename=$(basename "$archivo")
	echo -e "\nArchivo a procesar: $filename"

	# Checkeado de duplicado en PROCDIR/proc
	if [ -a "$procdir/proc/$filename" ]; then
		#Loggear cuando se tenga GLog
		echo "Se rechaza el archivo por estar DUPLICADO."

		#Mover con MOVER cuando se tenga
		#mv $archivo $rechdir/$filename
		continue
	fi

	# Checkeado de que la combinación COD_NORMA/COD_EMISOR sea válida
	filenxe=$(echo "$filename" | cut -d'_' -f2-3 --output-delimiter=";")
	findnxe=$(grep -o -E "$filenxe" $maedir/tab/nxe.tab)
	
	if [ ! -n "$findnxe" ]; then
		#Loggear cuando se tenga GLog
		echo "Se rechaza el archivo. Emisor no habilitado en este tipo de norma"

		#Mover con MOVER cuando se tenga
		#mv $archivo $rechdir/$filename
		continue
	fi

	#
	# Inicio procesado de archivo
	#
	gestionNom=$(echo "$filename" | cut -d'_' -f1)
	gestion=$(grep -E "$gestionNom" $maedir/gestiones.mae)	
	fechaIni=$(echo "$gestion" | cut -d';' -f 2)
	fechaFin=$(echo "$gestion" | cut -d';' -f 3)
	fechaIniDate=$(date -d "${fechaIni:6:4}-${fechaIni:3:2}-${fechaIni:0:2}" +"%Y%m%d")
	if [ "$fechaFin" == "NULL" ]; then
		fechaFinDate="99999999"
	else
		fechaFinDate=$(date -d "${fechaFin:6:4}-${fechaFin:3:2}-${fechaFin:0:2}" +"%Y%m%d")
	fi	
	fechaActual=$(date +"%Y%m%d")
	while read -r registro
	do
		#
		# Validación de registro
		#

		# Validación de fecha correcta
		fechaReg=$(echo "$registro" | cut -d';' -f1)
		if ! date -d "${fechaReg:6:4}-${fechaReg:3:2}-${fechaReg:0:2}" &> /dev/null;
		then
			# Falta manejo de registros rechazados
			echo "Registro rechazado. Fecha inválida"
			continue
		fi
	
		# Validación de fecha dentro de rango de gestión
		fechaRegDate=$(date -d "${fechaReg:6:4}-${fechaReg:3:2}-${fechaReg:0:2}" +"%Y%m%d")		
		if ! ([ $fechaIniDate -le $fechaRegDate ] && [ $fechaFinDate -ge $fechaRegDate ])
		then
			# Falta manejo de registros rechazados
			echo "Registro rechazado. Fecha fuera de rango de la gestión"
			continue	
		fi
		
		# Validación para registros históricos (los de anteriores mandatos, y del actual pero de años anteriores)
		if [ $(echo "$gestion" | cut -d';' -f 5) -eq 0 ] || [ "${fechaRegDate:0:4}" != "${fechaActual:0:4}" ]
		then
			norma=$(echo "$registro" | cut -d';' -f 2)
			if ! [[ $norma =~ ^-?[0-9]+$ ]]
			then
				# Falta manejo de registros rechazados
				echo "Registro rechazado. Número de norma inválido"
				continue
			else
				if [ $((norma)) -le 0 ]
				then
					# Falta manejo de registros rechazados
					echo "Registro rechazado. Número de norma inválido"
					continue
				else
					# Valido para protocolizar
					echo "Válido para protocolizar"
				fi
			fi
		else
			# Validación para registros corrientes (los de este mandato y este año)
			codfirma=$(echo "$registro" | cut -d';' -f 8)
			emisor=$(echo "$filename" | cut -d'_' -f 2)
			firmaemisor=$(grep -o "$codfirma" $maedir/emisores.mae | cut -d';' -f 3)
			if [ "$codfirma" != "$firmaemisor" ]
			then				
				# Falta manejo de registros rechazados
				echo "Registro rechazado. Código de firma inválido"
				continue
			else
				# Válido para protocolizar
				echo "Válido para protocolizar"
			fi
		fi
		#
		# Fin validación de registro
		#
	done < "$archivo"

	#
	# Fin procesado de archivo
	#
done

#
# Fin procesado
#

exit 0
