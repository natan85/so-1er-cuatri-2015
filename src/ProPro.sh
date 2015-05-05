#!/bin/bash

#
# Validaciones de argumentos
#

grupo="$GRUPO"
src="$grupo/src"
acepdir="$grupo/$ACEPDIR"
maedir="$grupo/$MAEDIR"
procdir="$grupo/$PROCDIR"
rechdir="$grupo/$RECHDIR"
logdir="$grupo/$LOGDIR"
archivos=()

function validarInicio {

	if [ "$1" == "--help" ]; then
		cat "ProProHelp.txt"
		exit 1
	fi

	# Checkeo de archivos y tablas disponibles
	if [ ! -d "$grupo" ]
	then
		echo "No se encuentra el directorio $grupo"
		exit 2
	fi

	if [ ! -d "$acepdir" ]
	then
		echo "No se encuentra el directorio $acepdir"
		exit 2
	fi

	if [ ! -d "$maedir" ]
	then
		echo "No se encuentra el directorio $maedir"
		exit 2
	else
		if [ ! -d "$maedir/tab" ]
		then
			echo "No se encuentra el directorio $maedir/tab"
			exit 2
		else
			if [ ! -w "$maedir/tab" ]
			then
				echo "No se tienen permisos para escribir sobre $maedir/tab"
				exit 2
			fi
		fi
	fi

	if [ ! -d "$procdir" ]
	then
		echo "No se encuentra el directorio $procdir"
		exit 2
	else
		if [ ! -w "$procdir" ]
		then	
			echo "No se tienen permisos para escribir sobre $procdir"
			exit 2
		fi
	fi

	if [ ! -d "$procdir/proc" ]
	then
		echo "No se encuentra el directorio $procdir/proc"
		exit 2
	else
		if [ ! -w "$procdir/proc" ]
		then	
			echo "No se tienen permisos para escribir sobre $procdir/proc"
			exit 2
		fi
	fi

	if [ ! -d "$rechdir" ]
	then
		echo "No se encuentra el directorio $rechdir"
		exit 2
	else
		if [ ! -w "$rechdir" ]
		then	
			echo "No se tienen permisos para escribir sobre $rechdir"
			exit 2
		fi
	fi

	if [ ! -d "$logdir" ]
	then
		echo "No se encuentra el directorio $logdir"
		exit 2
	fi

	# Verifica existencia de los archivos maestros y tablas, y permisos de lectura
	if [ ! -f "$maedir/emisores.mae" ]
	then
		echo "No se encuentra el archivo $maedir/emisores.mae"
		exit 2
	else
		if [ ! -r "$maedir/emisores.mae" ]
		then	
			echo "No se tienen permisos para leer $maedir/emisores.mae"
			exit 2
		fi
	fi

	if [ ! -f "$maedir/gestiones.mae" ]
	then
		echo "No se encuentra el archivo $maedir/gestiones.mae"
		exit 2
	else
		if [ ! -r "$maedir/gestiones.mae" ]
		then	
			echo "No se tienen permisos para leer $maedir/gestiones.mae"
			exit 2
		fi
	fi

	if [ ! -f "$maedir/tab/axg.tab" ]
	then
		echo "No se encuentra el archivo $maedir/tab/axg.tab"
		exit 2
	else
		if [ ! -r "$maedir/tab/axg.tab" ]
		then
			echo "No se tienen permisos para leer $maedir/tab/axg.tab"
			exit 2
		fi
	fi

	if [ ! -f "$maedir/tab/nxe.tab" ]
	then
		echo "No se encuentra el archivo $maedir/tab/nxe.tab"
		exit 2
	else
		if [ ! -r "$maedir/tab/nxe.tab" ]
		then
			echo "No se tienen permisos para leer $maedir/tab/nxe.tab"
			exit 2
		fi
	fi

	if [ ! -n "$(ls $acepdir)" ]
	then
		echo "No hay archivos para protocolizar en $acepdir"
		exit 3
	fi	
}

function buscarArchivosAceptados {
	$Glog "$nomCom" "$acepdir"
	# Búsqueda de archivos y ordenado por fecha
	for posFile in $(find "$acepdir" -printf "%p\n" | grep -v "~" | sort -t'_' -k5.7,5.10 -k5.4,5.5 -k5.1,5.2)
	do
		if [ -f $posFile ]; then
			archivos+=($posFile)	
		fi
	done
}

function validarArchivo {

	# Checkeado de duplicado en PROCDIR/proc
	if [ -a "$procdir/proc/$filename" ]; then
		cantRechazados=$((cantRechazados + 1))

		$Glog "$nomCom" "Se rechaza el archivo por estar DUPLICADO." "ERROR"

		$Mover $archivo "$rechdir" "ProPro"
		continue
	fi

	# Checkeado de que la combinación COD_NORMA/COD_EMISOR sea válida
	filenxe=$(echo "$filename" | cut -d'_' -f2-3 --output-delimiter=";")
	findnxe=$(grep -o -E "$filenxe" "$maedir/tab/nxe.tab")

	if [ ! -n "$findnxe" ]; then
		cantRechazados=$((cantRechazados + 1))

		$Glog "$nomCom" "Se rechaza el archivo. Emisor no habilitado en este tipo de norma" "ERROR"

		$Mover $archivo "$rechdir" "ProPro"
		continue
	fi
	cantAceptados=$((cantAceptados + 1))

}

function parsearFechasGestionRegistro {
	fechaIni=$(echo "$gestion" | cut -d';' -f 2)
	fechaFin=$(echo "$gestion" | cut -d';' -f 3)
	fechaIniDate=$(date -d "${fechaIni:6:4}-${fechaIni:3:2}-${fechaIni:0:2}" +"%Y%m%d")
	if [ "$fechaFin" == "NULL" ]; then
		fechaFinDate="99999999"
	else
		fechaFinDate=$(date -d "${fechaFin:6:4}-${fechaFin:3:2}-${fechaFin:0:2}" +"%Y%m%d")
	fi	
	fechaActual=$(date +"%Y%m%d")
}

function procesarRegistroRechazado {
	fuente=$filename
	motivo=$1
	registroRech="$fuente;$motivo;$registro"
	if [ -f $procdir/$gestionNom.rech ]
	then
		echo "$registroRech" >> $procdir/$gestionNom.rech
	else
		echo "$registroRech" > $procdir/$gestionNom.rech
	fi
}

function escribirRegistroValido {
	if [ -f $2 ]
	then
		echo "$1" >> $2
	else
		echo "$1" > $2
	fi
}

function procesarHistoricoValido {
	fuente=$filename
	anionorma="${fechaRegDate:0:4}"
	codnorma=$(echo "$filename" | cut -d'_' -f 2)
	codemisor=$(echo "$filename" | cut -d'_' -f 3)
	regHist="$fuente;$fechaReg;$norma;$anionorma;$causante;$extracto;$codtema;$expediente;$expedienteanio;$codfirma;$idregistro;$gestionNom;$codnorma;$codemisor"
	mkdir -p $procdir/$gestionNom
	escribirRegistroValido "$regHist" "$procdir/$gestionNom/$anionorma.$codnorma"
}

function maxContadorAxG {
	ultima=$(tac $maedir/tab/axg.tab | egrep -m1 .)
	contid=$(echo "$ultima" | cut -d';' -f 1)
	contid=$((contid + 1))
}

function actualizarTablaContador {
	mkdir -p $maedir/tab/ant
	
}

function calcularNormaCorriente {
	buscreg="$gestionNom;$anionorma;$codemisor;$codnorma;"
	contadorreg=$(grep -E "$buscreg" $maedir/tab/axg.tab)
	
	# Aun no terminado
	#actualizarTablaContador
	if [ -n "$contadorreg" ]
	then
		contnorma=$(echo "$contadorreg" | cut -d';' -f 6)
		buscreg="$gestionNom;$anionorma;$codemisor;$codnorma;$contnorma"
		contnorma=$(($contnorma+1))
		nuevoregaxg="$gestionNom;$anionorma;$codemisor;$codnorma;$contnorma"

		sed -i -e "s/$buscreg/$nuevoregaxg/g" $maedir/tab/axg.tab
	else
		contnorma=1
		maxContadorAxG

		usuario="$USER"
		fechaParaNuevoReg=$(date +"%d/%m/%Y")
		nuevoreg="$contid;$buscreg;$contnorma;$usuario;$fechaParaNuevoReg"
		echo "$nuevoreg" >> $maedir/tab/axg.tab

		$Glog "$nomCom" "Se actualizó la tabla de contadores" "INFO"
	fi	
	
}

function procesarCorrienteValido {
	fuente=$filename
	anionorma="${fechaRegDate:0:4}"
	codnorma=$(echo "$filename" | cut -d'_' -f 2)
	codemisor=$(echo "$filename" | cut -d'_' -f 3)
	regCorr="$fuente;$fechaReg;$contnorma;$anionorma;$causante;$extracto;$codtema;$expediente;$expedienteanio;$codfirma;$idregistro;$gestionNom;$codnorma;$codemisor"
	calcularNormaCorriente
	mkdir -p $procdir/$gestionNom
	escribirRegistroValido "$regCorr" "$procdir/$gestionNom/$anionorma.$codnorma"
	
}

function cargarDatosRegistro {
	gestionNom=$(echo "$filename" | cut -d'_' -f1)
	gestion=$(grep -m 1 "$gestionNom" $maedir/gestiones.mae)	
	norma=$(echo "$registro" | cut -d';' -f 2)
	fechaReg=$(echo "$registro" | cut -d';' -f 1)
	causante=$(echo "$registro" | cut -d';' -f 3)
	extracto=$(echo "$registro" | cut -d';' -f 4)
	codtema=$(echo "$registro" | cut -d';' -f 5)
	expediente=$(echo "$registro" | cut -d';' -f 6)
	expedienteanio=$(echo "$registro" | cut -d';' -f 7)
	codfirma=$(echo "$registro" | cut -d';' -f 8)
	idregistro=$(echo "$registro" | cut -d';' -f 9)
}

function validacionFechasRegistro {

	# Validación de fecha correcta
	if ! date -d "${fechaReg:6:4}-${fechaReg:3:2}-${fechaReg:0:2}" &> /dev/null;
	then
		procesarRegistroRechazado "Fecha inválida"
		continue
	fi
	
	# Validación de fecha dentro de rango de gestión
	fechaRegDate=$(date -d "${fechaReg:6:4}-${fechaReg:3:2}-${fechaReg:0:2}" +"%Y%m%d")
	if ! ([ $fechaIniDate -le $fechaRegDate ] && [ $fechaFinDate -ge $fechaRegDate ])
	then
		procesarRegistroRechazado "Fecha fuera de rango de la gestión"
		continue	
	fi		
}

function validacionHistoricos {
	if ! [[ $norma =~ ^-?[0-9]+$ ]]
	then
		procesarRegistroRechazado "Número de norma inválido"
		continue
	else
		if [ $((norma)) -le 0 ]
		then
			procesarRegistroRechazado "Número de norma inválido"
			continue
		else
			# Valido para protocolizar
			procesarHistoricoValido
		fi
	fi
}

function validacionCorrientes {
	# Validación para registros corrientes (los de este mandato y este año)
	emisor=$(echo "$filename" | cut -d'_' -f 2)
	firmaemisor=$(grep -o "$codfirma" $maedir/emisores.mae | cut -d';' -f 3)
	if [ "$codfirma" != "$firmaemisor" ]
	then				
		procesarRegistroRechazado "Código de firma inválido"
		continue
	else
		# Válido para protocolizar
		procesarCorrienteValido
	fi
}

function procesarRegistro {
	cargarDatosRegistro
	parsearFechasGestionRegistro
	validacionFechasRegistro
	if [ $(echo "$gestion" | cut -d';' -f 5) -eq 0 ] || [ "${fechaRegDate:0:4}" -ne "${fechaActual:0:4}" ]
	then
		validacionHistoricos
		
	else
		validacionCorrientes
	fi
}

function procesarArchivos {
	nomCom="ProPro"
	Glog="$GRUPO/$BINDIR/Glog.sh"
	Mover="$GRUPO/$BINDIR/Mover.sh"
	cantArchivos=$(printf '%s\n' "${archivos[@]}" | wc -l)
	cantAceptados=0
	cantRechazados=0
	$Glog "$nomCom" "Inicio de ProPro" "INFO"
	
	$Glog "$nomCom" "Cantidad de archivos a procesar: $cantArchivos" "INFO"

	for archivo in ${archivos[@]}
	do
		
		filename=$(basename "$archivo")
		$Glog "$nomCom" "Archivo a procesar: $filename" "INFO"
		validarArchivo
		
		read=false
		while read -r registro
		do
			read=true
			procesarRegistro
		done < "$archivo"
		
		if ! $read
		then
			registro=$(head -n 1 $archivo)
			procesarRegistro
		fi
	
		$Mover $archivo "$procdir/proc" "ProPro"
	done

	$Glog "$nomCom" "Cantidad de archivos procesados: $cantAceptados" "INFO"
	$Glog "$nomCom" "Cantidad de archivos rechazados: $cantRechazados" "INFO"
	$Glog "$nomCom" "Fin de ProPro" "INFO"
}

validarInicio
buscarArchivosAceptados
procesarArchivos
exit 0
