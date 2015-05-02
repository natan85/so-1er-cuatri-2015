# Command name (para pasarle a Glog)
cmdName="RecPro"

# Variable que guarda el path al root de la aplicación (reemplazar con /bin cuando se pongan todos en bin)
grupo="home/bliberini/TP/so-1er-cuatri-2015"

# Variable que guarda el path a NOVEDIR (reemplazar con la que se obtiene de configuración)
novedir="$grupo/noveDirMock"

# Variable que guarda el path a Glog (reemplazar con ./Glog.sh cuando se pongan todos en /bin)
glog="$grupo/Glog/Glog.sh"

# Variable de tiempo de espera hasta volver a ejecutarse (segundos)
sleepTime=30

# Variable que mantiene contador de ciclos de ejecución
timesExe=0

function verificarGestion {
}

function verificarNorma {
}

function verificarEmisor {
}

function verificarNroArchivo {
}

function verificarFecha {
}

function verificarCamposArchivosValidos {
	array=$1	
	codgestion=${array[0]}
	codnorma=${array[1]}
	codemisor=${array[2]}
	nroarchivo=${array[3]}
	fechaarchivo=${array[4]}
	
	verificarGestion $codgestion
	verificarNorma $codnorma
	verificarEmisor $codemisor
	verificarNroArchivo
	verificarFecha
}

function verificarFormatoNombreArchivo {
	filename=$1
	campos=$(echo "$filename" | tr "_" "\n")
	if [ ${#campos[@]} -ne 5 ]
	then
		echo "$1 rechazado"
	else
		verificarCamposArchivosValidos $campos
	fi	
}

function procesarArchivosNuevos {
	for archivo in $1
	do
		isText=$(file "$novedir/$archivo" | cut -f 2 -d' ')
		if [ $isText == "UTF-8" ] || [ $isText == "ASCII" ]
		then
			verificarFormatoNombreArchivo $archivo
		else
			echo "$archivo rechazado"
		fi
	done
}

function procesarArchivosPendientes {

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
done
