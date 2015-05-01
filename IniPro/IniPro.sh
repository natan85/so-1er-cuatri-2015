#!/bin/bash

comando="IniPro"

function cargar_glog {
	if [ ! -x "Glog/Glog.sh" ]; then
		echo "No tengo permisos suficientes para ejecutar Glog/Glog.sh. Esto debe ser corregido antes de ejecutar este comando."
		exit 1
	fi
	Glog="Glog/Glog.sh"
	export Glog
}

function verificar_ambiente_inicializado {
	#Verificar si el ambiente ya ha sido inicializado.
	if [ -n "$AMBIENTE_INICIALIZADO" ]; then
		#$Glog "IniPro" "El ambiente ya había sido inicializado. Avisando al usuario que vuelva a iniciar sesión para reiniciar. Abortando ejecución." "ERR"
		echo "El ambiente ya había sido inicializado. Si quiere reiniciar, por favor termine su sesión e ingrese nuevamente."
		exit 1
	fi	
}

function verificar_instalacion_completa {
	#Falta poner los archivos necesarios de la instalacion en general
	archivos_necesarios="MAEDIR/emisores.mae MAEDIR/normas.mae MAEDIR/gestiones.mae MAEDIR/tab/nxe.tab MAEDIR/tab/axg.tab"
	for archivo in $archivos_necesarios; do
		if [ ! -e $archivo ]; then
			#$Glog "IniPro" "Falta el archivo $archivo por lo que no puede continuar la ejecución." "ERR"
			echo "Falta el archivo $archivo por lo que no puede continuar la ejecución. Por favor instale nuevamente."
			exit 1
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
						exit 1
					fi
				fi
			fi
		fi
	done
}

function setear_variables_ambiente {
	CONFIG="CONFDIR/InsPro.conf"
	variables_ambiente="GRUPO CONFDIR BINDIR MAEDIR NOVEDIR DATASIZE ACEPDIR RECHDIR PROCDIR INFODIR DUPDIR LOGDIR LOGSIZE"
	for variable in $variables_ambiente; do
		eval $variable=$(grep '^'$variable'=' $CONFIG | sed 's/^'$variable'=\([^=]*\).*/\1/' | sed 's/\/*$//')
		eval export $variable
	done

	cargar_glog

	$Glog $comando "Directorio de configuración: $CONFDIR $(ls -l $GRUPO$CONFDIR)" "INFO"
	$Glog $comando "Directorio de ejecutables: $BINDIR $(ls -l $GRUPO$BINDIR)" "INFO"
	$Glog $comando "Directorio de maestros y tablas: $MAEDIR $(ls -l $GRUPO$MAEDIR)" "INFO"
	$Glog $comando "Directorio de recepción de documentos para protocolización: $NOVEDIR" "INFO"
	$Glog $comando "Directorio de archivos aceptados: $ACEPDIR" "INFO"
	
	$Glog $comando "Directorio de archivos rechazados: $RECHDIR" "INFO"
	$Glog $comando "Directorio de archivos protocolizados: $PROCDIR" "INFO"
	$Glog $comando "Directorio para informes y estadísticas: $INFODIR" "INFO"
	$Glog $comando "Nombre para el repositorio de duplicados: $DUPDIR" "INFO"
	$Glog $comando "Directorio para archivos de log: $LOGDIR $(ls -l $GRUPO$LOGDIR)" "INFO"
	$Glog $comando "Estado del sistema: INICIALIZADO" "INFO"
}

function preguntar_si_arrancar_rec_pro { 
	activar=""
	while [ "$activar" != "N" -a "$activar" != "S" ]; do
		read -p "¿Desea efectuar la activación de RecPro? [S/N] " activar
	done

	if [ $activar = "N" ]; then
		echo "Puede iniciar RecPro en otro momento usando Start/Start.sh RecPro/RecPro.sh"
	else
		#Chequear si RecPro está corriendo? O lo hace Start?
		"Start/Start.sh RecPro/RecPro.sh"
		echo "Puede finalizar RecPro usando Stop/Stop.sh"
	fi

}

verificar_ambiente_inicializado
verificar_instalacion_completa
verificar_permisos
setear_variables_ambiente
preguntar_si_arrancar_rec_pro
exit 0
