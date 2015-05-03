#!/bin/bash

comando="IniPro"

function cargar_glog {
	if [ ! -x "$GRUPO/$BINDIR/Glog.sh" ]; then
		echo "No tengo permisos suficientes para ejecutar $BINDIR/Glog.sh. Esto debe ser corregido antes de ejecutar este comando."
		return 1
		#exit 1
	fi
	Glog="$GRUPO/$BINDIR/Glog.sh"
	export Glog
}

function verificar_ambiente_inicializado {
	#Verificar si el ambiente ya ha sido inicializado.
	if [ -n "$AMBIENTE_INICIALIZADO" ]; then
		#$Glog "IniPro" "El ambiente ya había sido inicializado. Avisando al usuario que vuelva a iniciar sesión para reiniciar. Abortando ejecución." "ERR"
		echo "El ambiente ya había sido inicializado. Si quiere reiniciar, por favor termine su sesión e ingrese nuevamente."
		return 1
		#exit 1
	fi	
	AMBIENTE_INICIALIZADO="1"
}

function verificar_instalacion_completa {
	#Falta poner los archivos necesarios de la instalacion en general
	archivos_necesarios="$GRUPO/$MAEDIR/emisores.mae $GRUPO/$MAEDIR/normas.mae $GRUPO/$MAEDIR/gestiones.mae $GRUPO/$MAEDIR/tab/nxe.tab $GRUPO/$MAEDIR/tab/axg.tab"
	for archivo in $archivos_necesarios; do
		if [ ! -e $archivo ]; then
			#$Glog "IniPro" "Falta el archivo $archivo por lo que no puede continuar la ejecución." "ERR"
			echo "Falta el archivo $archivo por lo que no puede continuar la ejecución. Por favor instale nuevamente."
			return 1
			#exit 1
		fi
	done
}

function verificar_permisos {
	for archivo in $archivos_necesarios; do
		if [ ! -r $archivo ]; then
			chmod +004 $archivo			
			if [ $? -ne 0 ]; then
				chmod +040 $archivo
				if [ $? -ne 0 ]; then
					chmod +400 $archivo
					if [ $? -ne 0 ]; then
						echo "El archivo $archivo no es leíble, y no tengo privilegio para cambiar los permisos del mismo. Cámbielos usando sudo y vuelva a ejecutar."
						return 1
						#exit 1
					fi
				fi
			fi
		fi
	done
}

function cargar_variables_ambiente {
	CONFIG="conf/InsPro.conf"
	variables_ambiente="GRUPO CONFDIR BINDIR MAEDIR NOVEDIR DATASIZE ACEPDIR RECHDIR PROCDIR INFODIR DUPDIR LOGDIR LOGSIZE"
	for variable in $variables_ambiente; do
		eval $variable=$(grep '^'$variable'=' $CONFIG | sed 's/^'$variable'=\([^=]*\).*/\1/' | sed 's/\/*$//')
	done
}

function setear_variables_ambiente {
	for variable in $variables_ambiente; do
		eval export $variable
	done

	cargar_glog
	if [ $? -eq 1 ]; then return 1; fi

	$Glog $comando "Directorio de configuración: $CONFDIR $(ls -l $GRUPO/$CONFDIR)" "INFO"
	$Glog $comando "Directorio de ejecutables: $BINDIR $(ls -l $GRUPO/$BINDIR)" "INFO"
	$Glog $comando "Directorio de maestros y tablas: $MAEDIR $(ls -l $GRUPO/$MAEDIR)" "INFO"
	$Glog $comando "Directorio de recepción de documentos para protocolización: $NOVEDIR" "INFO"
	$Glog $comando "Directorio de archivos aceptados: $ACEPDIR" "INFO"
	
	$Glog $comando "Directorio de archivos rechazados: $RECHDIR" "INFO"
	$Glog $comando "Directorio de archivos protocolizados: $PROCDIR" "INFO"
	$Glog $comando "Directorio para informes y estadísticas: $INFODIR" "INFO"
	$Glog $comando "Nombre para el repositorio de duplicados: $DUPDIR" "INFO"
	$Glog $comando "Directorio para archivos de log: $LOGDIR $(ls -l $GRUPO/$LOGDIR)" "INFO"
	$Glog $comando "Estado del sistema: INICIALIZADO" "INFO"
}

function preguntar_si_arrancar_rec_pro { 
	activar=""
	while [ "$activar" != "N" -a "$activar" != "S" ]; do
		read -p "¿Desea efectuar la activación de RecPro? [S/N] " activar
	done

	if [ $activar = "N" ]; then
		echo "Puede iniciar RecPro en otro momento usando $BINDIR/Start.sh $BINDIR/RecPro.sh"
	else
		#Chequear si RecPro está corriendo? O lo hace Start?
		bash "$GRUPO/$BINDIR/Start.sh \"$GRUPO/$BINDIR/RecPro.sh\""
		echo "Puede finalizar RecPro usando $BINDIR/Stop.sh"
	fi

}

verificar_ambiente_inicializado
if [ $? -eq 1 ]; then return 1; fi
cargar_variables_ambiente
verificar_instalacion_completa
if [ $? -eq 1 ]; then return 1; fi
verificar_permisos
if [ $? -eq 1 ]; then return 1; fi
setear_variables_ambiente
if [ $? -eq 1 ]; then return 1; fi
preguntar_si_arrancar_rec_pro
export AMBIENTE_INICIALIZADO
return 0
#exit 0
