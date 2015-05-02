# Command name (para pasarle a Glog)
cmdName="RecPro"

# Variable que guarda el path al root de la aplicación (reemplazar con /bin cuando se pongan todos en bin)
grupo="home/bliberini/TP/so-1er-cuatri-2015"

# Variable que guarda el path a NOVEDIR (reemplazar con la que se obtiene de configuración)
novedir="$grupo/noveDirMock"

# Variable que guarda el path a ACEPDIR (reemplazar con la que se obtiene de configuración)
acepdir="$grupo/acepDirMock"

# Variable que guarda el path a Glog (reemplazar con ./Glog.sh cuando se pongan todos en /bin)
glog="$grupo/Glog/Glog.sh"

# Variable de tiempo de espera hasta volver a ejecutarse (segundos)
sleepTime=30

# Variable que mantiene contador de ciclos de ejecución
timesExe=0

# Variable que guarda la dirección del directorio de maestros (reemplazar con la que se obtiene de configuración)
maedir="$grupo/maeDirMock"

# Variable que guarda la dirección del directorio de rechazados (reemplazar con la que se obtiene de configuración)
rechdir="$grupo/rechDirMock"

# Variable que guarda el registro de la gestión del archivo, si la encuentra
gestion=""

function moverRechazado {
	filename=$1
	pathOrigen="$novedir/$filename"
	pathDestino="$rechdir/$filename"

	# Falta invocar a MOVE
}

function moverArchivoValido {
	pathOrigen="$novedir/$1"
	pathDestino="$2/$1"

	# Falta invocar a MOVE	
}


function verificarGestion {
	gestion=$(grep -E "^$1" "$maedir/gestiones.mae")
	if [ ! -n "$gestion" ]
	then
		$glog $cmdName "$2 rechazado: Gestión inválida" "ERROR"
		moverRechazado $filename
		continue
	fi
}

function verificarNorma {
	row=$(grep -E "^$1" "$maedir/normas.mae")
	if [ ! -n "$row" ]
	then
		$glog $cmdName "$2 rechazado: Norma inválida" "ERROR"
		moverRechazado $filename
		continue
	fi
}

function verificarEmisor {
	row=$(grep -E "^$1" "$maedir/emisores.mae")
	if [ ! -n "$row" ]
	then
		$glog $cmdName "$2 rechazado: Emisor inválido" "ERROR"
		moverRechazado $filename
		continue
	fi
}

function verificarNroArchivo {	
	re='^[0-9]+$'
	if ! [[ $1 =~ $re ]]
	then
		$glog $cmdName "$2 rechazado: Número de archivo inválido" "ERROR"
		moverRechazado $filename		
		continue
	fi
}

function verificarFecha {
	fecha=$1
	if ! date -d "${fecha:6:4}-${fecha:3:2}-${fecha:0:2}" &> /dev/null
	then
		$glog $cmdName "$2 rechazado: Formato de fecha inválida" "ERROR"
		moverRechazado $filename
		continue
	else
		fechaIni=$(echo "$gestion" | cut -d';' -f 2)
		fechaFin=$(echo "$gestion" | cut -d';' -f 3)
		fechaIniDate=$(date -d "${fechaIni:6:4}-${fechaIni:3:2}-${fechaIni:0:2}" +"%Y%m%d")
		if [ "$fechaFin" == "NULL" ]; then
			fechaFinDate=$(date +"%Y%m%d")
		else
			fechaFinDate=$(date -d "${fecha:6:4}-${fecha:3:2}-${fecha:0:2}" +"%Y%m%d")
		fi	
		fechaReg=$(date -d "${fechaIni:6:4}-${fechaIni:3:2}-${fechaIni:0:2}" +"%Y%m%d")
		if ! ([ $fechaIniDate -le $fechaReg ] && [ $fechaFinDate -ge $fechaReg ])
		then
			$glog $cmdName "$2 rechazado: Fecha fuera del rango de gestión" "ERROR"
			moverRechazado $filename
			continue	
		fi		
	fi
}

function verificarArchivoNoVacio {
	filename=$1
	contenido=$(cat "$novedir/$filename")
	if [ ! -n "$contenido" ]
	then
		$glog $cmdName "$filename rechazado: Archivo vacío" "ERROR"
		moverRechazado $filename
		continue
	fi
}

function verificarCamposArchivosValidos {
	array=$1	
	codgestion=${array[0]}
	codnorma=${array[1]}
	codemisor=${array[2]}
	nroarchivo=${array[3]}
	fechaarchivo=${array[4]}
	
	verificarGestion $codgestion $2
	verificarNorma $codnorma $2
	verificarEmisor $codemisor $2
	verificarNroArchivo $nroarchivo $2
	verificarFecha $fechaarchivo $2
	verificarArchivoNoVacio $2
}

function verificarFormatoNombreArchivo {
	filename=$1
	campos=$(echo "$filename" | tr "_" "\n")
	if [ ${#campos[@]} -ne 5 ]
	then
		$glog $cmdName "$filename rechazado: Nombre de archivo inválido" "ERROR"
		moverRechazado $filename
	else
		verificarCamposArchivosValidos $campos $filename
	fi	
}

function procesarArchivoValido {
	filename=$1
	gestionnom=$(echo $gestion | cut -d';' -f 1)
	mkdir -p $acepdir/$gestionnom
	moverArchivoValido $filename "$acepdir/$gestionnom"
	$glog $cmdName "$filename aceptado: se mueve a $acepdir/$gestionnom/$filename" "INFO"
}

function procesarArchivosNuevos {
	for archivo in $1
	do
		isText=$(file "$novedir/$archivo" | cut -f 2 -d' ')
		if [ $isText == "UTF-8" ] || [ $isText == "ASCII" ]
		then
			verificarFormatoNombreArchivo $archivo
			procesarArchivoValido $filename
		else
			$glog $cmdName "$archivo rechazado: No es un archivo de texto" "ERROR"
			moverRechazado $filename
		fi
	done
}

function procesarArchivosPendientes {
	pendientes=$()
}

function checkearArchivosNuevos {
	newFiles=$(ls $novedir)
	if [ -n "$newFiles" ]
	then
		procesarArchivosNuevos $newFiles
	else
		procesarArchivosPendientes
	fi
}

while true
do
	timesExe=$(($timesExe + 1))
	$glog $cmdName "RecPro ciclo nro. $timesExe" "INFO"
	checkearArchivosNuevos
	sleep $sleepTime	 
done
exit 0
