# Command name (para pasarle a Glog)
cmdName="RecPro"

# Variable que guarda el path al root de la aplicación
grupo="$GRUPO"

# Variable que guarda el path a NOVEDIR
novedir="$GRUPO/$NOVEDIR"

# Variable que guarda el path a ACEPDIR
acepdir="$GRUPO/$ACEPDIR"

# Variable que guarda el path a Glog
glog="$GRUPO/$BINDIR/Glog.sh"

# Variable que guarda el path a Mover
mover="$GRUPO/$BINDIR/Mover.sh"

# Variable de tiempo de espera hasta volver a ejecutarse (segundos)
sleepTime=30

# Variable que mantiene contador de ciclos de ejecución
timesExe=0

# Variable que guarda la dirección del directorio de maestros
maedir="$GRUPO/$MAEDIR"

# Variable que guarda la dirección del directorio de rechazados
rechdir="$GRUPO/$RECHDIR"

# Variable que guarda el path a ProPro
propro="$GRUPO/$BINDIR/ProPro.sh"

# Variable que guarda el registro de la gestión del archivo, si la encuentra
gestion=""

# Flag que verifica si hay archivos pendientes a procesar en ACEPDIR
hayArchivosPendientes=false

function moverRechazado {
	filename=$1
	pathOrigen="$novedir/$filename"
	pathDestino="$rechdir"
	"$mover" "$pathOrigen" "$pathDestino" "RecPro"
}

function moverArchivoValido {
	pathOrigen="$novedir/$1"
	pathDestino="$2"
	"$mover" "$pathOrigen" "$pathDestino" "RecPro"	
}


function verificarGestion {
	gestion=$(grep -E "^$1;" "$maedir/gestiones.mae")
	if [ ! -n "$gestion" ]
	then
		$glog $cmdName "$2 rechazado: Gestión inválida" "ERROR"
		moverRechazado $2
		continue
	fi
}

function verificarNorma {
	row=$(grep -E "^$1;" "$maedir/normas.mae")
	if [ ! -n "$row" ]
	then
		$glog $cmdName "$2 rechazado: Norma inválida" "ERROR"
		moverRechazado $2
		continue
	fi
}

function verificarEmisor {
	row=$(grep -E "^$1;" "$maedir/emisores.mae")
	if [ ! -n "$row" ]
	then
		$glog $cmdName "$2 rechazado: Emisor inválido" "ERROR"
		moverRechazado $2
		continue
	fi
}

function verificarNroArchivo {	
	re='^[0-9]+$'
	if ! [[ $1 =~ $re ]]
	then
		$glog $cmdName "$2 rechazado: Número de archivo inválido" "ERROR"
		moverRechazado $2		
		continue
	fi
}

function verificarFecha {
	fecha=$1
	if ! date -d "${fecha:6:4}-${fecha:3:2}-${fecha:0:2}" &> /dev/null
	then
		$glog $cmdName "$2 rechazado: Formato de fecha inválida" "ERROR"
		moverRechazado $2
		continue
	else
		fechaIni=$(echo "$gestion" | cut -d';' -f 2)
		fechaFin=$(echo "$gestion" | cut -d';' -f 3)
		fechaIniDate=$(date -d "${fechaIni:6:4}-${fechaIni:3:2}-${fechaIni:0:2}" +"%Y%m%d")
		if [ "$fechaFin" == "NULL" ]; then
			fechaFinDate=$(date +"%Y%m%d")
		else
			fechaFinDate=$(date -d "${fechaFin:6:4}-${fechaFin:3:2}-${fechaFin:0:2}" +"%Y%m%d")
		fi	
		fechaReg=$(date -d "${fecha:6:4}-${fecha:3:2}-${fecha:0:2}" +"%Y%m%d")
		if ! ([ $fechaIniDate -le $fechaReg ] && [ $fechaFinDate -ge $fechaReg ])
		then
			$glog $cmdName "$2 rechazado: Fecha fuera del rango de gestión" "ERROR"
			moverRechazado $2
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
	filename=$1
	IFS='_' read -a array <<< "$filename"
	codgestion=${array[0]}
	codnorma=${array[1]}
	codemisor=${array[2]}
	nroarchivo=${array[3]}
	fechaarchivo=${array[4]}
	
	verificarGestion $codgestion $1
	verificarNorma $codnorma $1
	verificarEmisor $codemisor $1
	verificarNroArchivo $nroarchivo $1
	verificarFecha $fechaarchivo $1
	verificarArchivoNoVacio $1
	procesarArchivoValido $1
}

function verificarFormatoNombreArchivo {
	filename=$1
	IFS='_' read -a campos <<< "$filename"
	if [ ${#campos[@]} -ne 5 ]
	then
		$glog $cmdName "$filename rechazado: Nombre de archivo inválido" "ERROR"
		moverRechazado $filename
	else
		verificarCamposArchivosValidos $filename
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
		if [ $isText == "empty" ]
		then
			$glog $cmdName "$archivo rechazado: Archivo vacío" "ERROR"
			moverRechazado $archivo
		else
			if [ $isText == "UTF-8" ] || [ $isText == "ASCII" ]
			then
				verificarFormatoNombreArchivo $archivo
			else
				$glog $cmdName "$archivo rechazado: No es un archivo de texto" "ERROR"
				moverRechazado $archivo
			fi
		fi
	done
}

function checkearArchivosAcepdir {
	pendientes=$1
	path=$2
	for entry in $pendientes
	do
		if [ -d $entry ]
		then
			contenido=$(ls -1 "$path/$entry")
			for file in $contenido
			do
				if [ -f $file ]
				then
					hayArchivos=true
				fi
				if [ $hayArchivos ]
				then
					break;
				fi
			done
		else
			if [ -f $entry ]
			then
				hayArchivos=true
			fi
		fi
		if [ $hayArchivos ]
		then
			break;
		fi
	done	
}

function llamarAProPro {
	proproCorriendo=$(pgrep "ProPro")
	if [ ! -n "$proproCorriendo" ]
	then
		# Modificar para que se llame con Start
		$propro
		proproCorriendo=$(pgrep "ProPro")
		$glog $cmdName "ProPro corriendo bajo el no.: $proproCorriendo" "INFO"
	else
		$glog $cmdName "Invocación de ProPro pospuesta para el siguiente ciclo" "INFO"
	fi
}

function procesarArchivosPendientes {
	pendientes=$(ls -1 $acepdir)
	if [ ! -n "$pendientes" ]
	then
		checkearArchivosAcepdir $pendientes "$acepdir"
		if [ $hayArchivos ]
		then
			llamarAProPro
		fi
	fi	
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
