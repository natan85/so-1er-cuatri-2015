#!/bin/bash

# *************************************************************************
# (75.08) Sistemas Operativos  fiuba
# 1er Cuatrimestre 2015
# Grupo 08 - Trabajo Practico H
# *************************************************************************
#
# InsPro.sh
# Script para la instalacion del paquete SisProH
#

# Exit Codes
# 0 - Instalacion Completa
# 1 - Ningun componente instalado
# 2 - Instalacion Incompleta

GRUPO=`pwd`
INSTDIR="src"
CONFDIR="conf"
MAEDIR="mae"
BINDIR="bin"
NOVEDIR="novedades"
DATASIZE=100 #MB
LOGDIR="log"
LOGSIZE=400000 #bytes
LOGFILE="$CONFDIR/InsPro.log"
CONFFILE="$CONFDIR/InsPro.conf"
CONFFILEAUX="$CONFDIR/.temp"
ACEPDIR="a_protocolizar"
INFODIR="informes"
RECHDIR="rechazados"
PROCDIR="protocolizados"
DUPDIR="dup"

# variables que indican si ya se enuentra instalado
BMAEDIR=0
BBINDIR=0
BNOVEDIR=0
BDATASIZE=0
BLOGDIR=0
BLOGSIZE=0
BLOGFILE=0
BCONFFILE=0
BACEPDIR=0
BINFODIR=0
BRECHDIR=0
BPROCDIR=0
BDUPDIR=0


function toLower() {
    echo $1 | tr "[:upper:]" "[:lower:]"
}

##################################################
#tipos de mensajes de informacion para el Log
MSGWAR='WAR'
MSGINFO='INFO'
MSGERR='ERR'

function loguear() {
    logDate=`date "+%Y%m%d %H:%M:%S"`
    echo "$logDate-$USER-InsPro-$1-$2" >> $LOGFILE
}

function echoAndLog() {
    echo -e "$2"
    loguear "$1" "$2"
}



###################################################
#Chequear si se puede escribir el dir actual, y si existe la carpeta de los sources
function chequeoInicial() {
    if [ ! -w "$GRUPO" ]; then
        echo "No tiene permisos de escritura en el directorio de instalación"
        echo "Instalación cancelada"
        exit 2
    fi

    if [ ! -d "$GRUPO/$INSTDIR" ]; then
        echo "No existe el directorio $INSTDIR"
        echo "Instalación cancelada"
        exit 2
    elif [ ! -w "$GRUPO/$INSTDIR" ]; then
        echo "No tiene permisos de escritura sobre el directorio $INSTDIR"
        echo "Instalación cancelada"
        exit 2
    fi
}
################################################
#Funcion para crear directorios
#Parametros:
#1 - Permisos 
#2 - Path del directorio a crear
function crearDirectorio() {
    if [ ! -d "$2" ]; then
        mkdir -p -m$1 "$2" 2>/dev/null
    fi
}

##############################################################################
#Presentación inicial de la Instalación
function presentacion() {
    echo "***************************************************************************"
    echo "*     TP SO7508 Primer Cuatrimestre 2015. Tema H Copyright © Grupo 08     *"
    loguear $MSGINFO "TP SO7508 Primer Cuatrimestre 2015. Tema H Copyright © Grupo 08"
    echo "***************************************************************************"
    loguear $MSGINFO "Al instalar TP SO7508 Primer Cuatrimestre 2015 UD. expresa estar en un todo de acuerdo con los términos y condiciones del \"ACUERDO DE LICENCIA DE SOFTWARE\" incluido en este paquete."
    echo "* Al instalar TP SO7508 Primer Cuatrimestre 2015 UD. expresa estar en un  *"
    echo "* todo de acuerdo  con los términos y condiciones del \"ACUERDO DE         *"
    echo "* LICENCIA DE SOFTWARE\" incluido en este paquete.                         *"
    echo "***************************************************************************"
    echoAndLog $MSGINFO "Acepta? (Si/No): "

    read respuesta

    loguear $MSGINFO "$respuesta"
        
    if [ "$respuesta" = "" ] || [ `toLower $respuesta` != "si" ]; then
        echoAndLog $MSGINFO "Instalacion Cancelada"
        exit 1
    fi
}
#######################################################################
#Funcion que verifica si la version de perl instalada es 5 o superior
#Return Codes:
#    0 - La version instalada es 5 o superior
#    1 - No esta instalado perl o la version es menor a 5
function verificarPerl() {
    perlVersion=`perl --version | grep -o "v[5-9]\.[0-9]\{1,\}\.[0-9]\{1,\}"`
    if [ $? -ne 0 ]; then
        echoAndLog $MSGWAR "Para instalar Consultar es necesario contar con  Perl 5 o superior instalado."
        echoAndLog $MSGWAR "Efectúe su instalación e inténtelo nuevamente. Proceso de Instalación Cancelado."
        exit 1
    else
        echoAndLog $MSGINFO "Version de Perl instalada: $perlVersion"
    fi
}

function mensajesInformativos() {
    echoAndLog $MSGINFO "Todos los directorios del sistema serán subdirectorios de $GRUPO"
    echoAndLog $MSGINFO "Todos los componentes de la instalación se obtendrán del repositorio: $GRUPO/$INSTDIR"
    listado=`ls "$GRUPO/$INSTDIR"`
    echoAndLog $MSGINFO "Contenido del repositorio: \n$listado\n"
    echoAndLog $MSGINFO "El log de la instalación se almacenara en $GRUPO/$CONFDIR"
	echo ""
    echoAndLog $MSGINFO "Al finalizar la instalación, si la misma fue exitosa se dejara un archivo de configuración en $GRUPO/$CONFDIR"
	echo ""
}

function definirDirBinarios() {
if [ $BBINDIR -ne 0 ]; then
    isOk=0
    echo "No llega a entrar aca"
    while [ "$isOk" -eq 0 ]; do
        echoAndLog $MSGINFO "Defina el directorio de instalacion de los ejecutables ($BINDIR):"
        read dirBin
        if [ ! -z "$dirBin" ]; then
            value=`echo $dirBin | grep "^\(\w\|_\)\+\(/\(\w\|_\)\+\)*$"`
            if [ $? -eq 0 ]; then
                BINDIR=$dirBin

                isOk=1
            else
                echoAndLog $MSGERR "$dirBin no es un nombre de directorio valido."
            fi
        else
            isOk=1
        fi 
    done
    loguear $MSGINFO "Directorio de ejecutables: $BINDIR"
fi
    guardarBin "$CONFFILEAUX"
}

function definirDirMae() {
if [ $BMAEDIR -ne 0 ]; then
    isOk=0
    while [ "$isOk" -eq 0 ]; do
        echoAndLog $MSGINFO "Defina el directorio para maestros y tablas ($MAEDIR):"
        read dirMae
        if [ ! -z "$dirMae" ]; then
            value=`echo $dirMae | grep "^\(\w\|_\)\+\(/\(\w\|_\)\+\)*$"`
            if [ $? -eq 0 ]; then
                MAEDIR=$dirMae
                isOk=1
            else
                echoAndLog $MSGERR "$dirMae no es un nombre de directorio valido."
        echo ""
            fi
        else
            isOk=1
        fi 
    done
    loguear $MSGINFO "Directorio para maestros y tablas: $MAEDIR"
    fi
    guardarMae "$CONFFILEAUX"
}

function definirDirNovedades() {
if [ $BNOVEDIR -ne 0 ]; then
    isOk=0
    while [ "$isOk" -eq 0 ]; do
        echoAndLog $MSGINFO "Defina en directorio de recepcion de documentos Protocolizados ($NOVEDIR):"
        read dirnovedades
        if [ ! -z "$dirnovedades" ]; then
            value=`echo $dirnovedades | grep "^\(\w\|_\)\+\(/\(\w\|_\)\+\)*$"`
            if [ $? -eq 0 ]; then
                NOVEDIR=$dirnovedades
                isOk=1
            else
                echoAndLog $MSGERR "$dirnovedades no es un nombre de directorio valido."
        echo ""
            fi
        else
            isOk=1
        fi 
    done
    loguear $MSGINFO "Directorio de arribo de novedades: $NOVEDIR"
    fi
    guardarNove "$CONFFILEAUX"
}

function definirDatasize(){
    #Espacio disponible para NOVEDIR
if [ $BDATASIZE -ne 0 ]; then
    freeSize=0
    while [ $freeSize -lt $DATASIZE ]; do
        isOk=0
        while [ "$isOk" -eq 0 ]; do    
            echoAndLog $MSGINFO "Defina el espacio minimo libre para el arribo de estas novedades en Mbytes ($DATASIZE):"
            read dataSize
            if [ ! -z $dataSize ]; then
                value=`echo $dataSize | grep "^[0-9]\+$"`
                if [ $? -eq 0 ]; then
                    DATASIZE=$dataSize
                    isOk=1
                else
                    echoAndLog $MSGERR "$dataSize no es un valor válido. Ingrese un valor numérico"
            echo ""
                fi
            else
                isOk=1
            fi
        done

        #Chequeo espacio disponible en disco
        freeSize=`df "$GRUPO" | tail -n 1 | sed 's/\s\+/ /g' | cut -d ' ' -f 4`
        let freeSize=$freeSize/1024
        if [ $freeSize -lt $DATASIZE ]; then
            echoAndLog $MSGERR "Insuficiente espacio en disco."
            echoAndLog $MSGERR  "Espacio disponible: $freeSize MB."
            echoAndLog $MSGERR "Espacio requerido $DATASIZE MB."
        echo ""
        fi
    done
    loguear $MSGINFO "Espacio para el arribo de novedades en MB: $DATASIZE"
    fi
    guardarDatasize "$CONFFILEAUX"
}

function definirDirAceptados() {
if [ $BACEPDIR -ne 0 ]; then
    isOk=0
    while [ "$isOk" -eq 0 ]; do
        echoAndLog $MSGINFO "Defina el directorio de grabación de las Novedades aceptadas ($ACEPDIR):"
        read dirAcep
        if [ ! -z "$dirAcep" ]; then
            value=`echo $dirAcep | grep "^\(\w\|_\)\+\(/\(\w\|_\)\+\)*$"`
            if [ $? -eq 0 ]; then
                ACEPDIR=$dirAcep
                isOk=1
            else
                echoAndLog $MSGERR "$dirAcep no es un nombre de directorio valido."
        echo ""
            fi
        else
            isOk=1
        fi 
    done
    loguear $MSGINFO "Directorio de grabación de las Novedades aceptadas: $ACEPDIR"
    fi
    guardarAcep "$CONFFILEAUX"
}

function definirDirInformes() {
  if [ $BINFODIR -ne 0 ]; then
    isOk=0
    while [ "$isOk" -eq 0 ]; do
        echoAndLog $MSGINFO "Defina el directorio de grabación de los informes de salida ($INFODIR):"
        read dirInfo
        if [ ! -z "$dirInfo" ]; then
            value=`echo $dirInfo | grep "^\(\w\|_\)\+\(/\(\w\|_\)\+\)*$"`
            if [ $? -eq 0 ]; then
                INFODIR=$dirInfo
                isOk=1
            else
                echoAndLog $MSGERR "$dirInfo no es un nombre de directorio valido."
        echo ""
            fi
        else
            isOk=1
        fi 
    done
    loguear $MSGINFO "Directorio de grabación de los informes de salida: $INFODIR"
    fi
    guardarInfo "$CONFFILEAUX"
}

function definirDirLog() {
if [ $BLOGDIR -ne 0 ]; then
    isOk=0
    while [ "$isOk" -eq 0 ]; do
        echoAndLog $MSGINFO "Defina el nombre del directorio de log ($LOGDIR):"
        read dirLog
        if [ ! -z "$dirLog" ]; then
            value=`echo $dirLog | grep "^\(\w\|_\)\+\(/\(\w\|_\)\+\)*$"`
            if [ $? -eq 0 ]; then
                LOGDIR=$dirLog
                isOk=1
            else
                echoAndLog $MSGERR "$dirLog no es un nombre de directorio valido."
        echo ""
            fi
        else
            isOk=1
        fi 
    done
    loguear $MSGINFO "Directorio de log: $LOGDIR"
    fi
    guardarLog "$CONFFILEAUX"
}
function definirLogsize() {
    #Tamaño maximo para archivos de log
 if [ $BLOGSIZE -ne 0 ]; then
  isOk=0
    while [ "$isOk" -eq 0 ]; do    
    echoAndLog $MSGINFO "Defina el tamaño máximo para los archivos de log en bytes ($LOGSIZE):"
    read logSize
    if [ ! -z $logSize ]; then
        value=`echo $logSize | grep "^[0-9]\+$"`
        if [ $? -eq 0 ]; then
            LOGSIZE=$logSize
            isOk=1
        else
            echoAndLog $MSGERR "$logSize no es un valor válido. Ingrese un valor numérico"
        echo ""
        fi
    else
        isOk=1
    fi
    done
    loguear $MSGINFO "Tamaño máximo para archivos de log: $LOGSIZE"
    fi
    guardarLogsize "$CONFFILEAUX"
}

function definirDirRechazados() {
if [ $BRECHDIR -ne 0 ]; then
    isOk=0
    while [ "$isOk" -eq 0 ]; do
        echoAndLog $MSGINFO "Defina el directorio de grabación de Archivos Rechazados ($RECHDIR):"
        read dirRech
        if [ ! -z "$dirRech" ]; then
            value=`echo $dirRech | grep "^\(\w\|_\)\+\(/\(\w\|_\)\+\)*$"`
            if [ $? -eq 0 ]; then
                RECHDIR=$dirRech
                isOk=1
            else
                echoAndLog $MSGERR "$dirRech no es un nombre de directorio valido."
        echo ""
            fi
        else
            isOk=1
        fi 
    done
    loguear $MSGINFO "Directorio de grabación de Archivos Rechazados: $RECHDIR"
    fi
    guardarRech "$CONFFILEAUX"
}

function definirDirProtocolizados() {
if [ $BPROCDIR -ne 0 ]; then
 isOk=0
    while [ "$isOk" -eq 0 ]; do
        echoAndLog $MSGINFO "Ingrese el nombre del directorio de grabación de Archivos Protocolizados ($PROCDIR):"
        read dirProt
        if [ ! -z "$dirProt" ]; then
            value=`echo $dirProt | grep "^\(\w\|_\)\+\(/\(\w\|_\)\+\)*$"`
            if [ $? -eq 0 ]; then
                PROCDIR=$dirProt
                isOk=1
            else
                echoAndLog $MSGERR "$dirProt no es un nombre de directorio valido.\n"
            fi
        else
            isOk=1
        fi 
    done
    loguear $MSGINFO "Directorio de grabación de Archivos Protocolizados: $PROCDIR"
    fi
    guardarProc "$CONFFILEAUX"
}

function definirDirDuplicados() {
if [ $BDUPDIR -ne 0 ]; then
   isOk=0
    while [ "$isOk" -eq 0 ]; do
        echoAndLog $MSGINFO "Defina el nombre para ek repositorio de Archivos Duplicados ($DUPDIR):"
        read dirDup
        if [ ! -z "$dirDup" ]; then
            value=`echo $dirDup | grep "^\(\w\|_\)\+\(/\(\w\|_\)\+\)*$"`
            if [ $? -eq 0 ]; then
                DUPDIR=$dirDup
                isOk=1
            else
                echoAndLog $MSGERR "$dirDup no es un nombre de directorio valido.\n"
            fi
        else
            isOk=1
        fi 
    done
    loguear $MSGINFO "Directorio de Archivos Duplicados: $DUPDIR"
    fi
    guardarDup "$CONFFILEAUX"
}
 
function mostrarConfiguracion() {
    echoAndLog $MSGINFO "********************************************************"
    echoAndLog $MSGINFO "* Parámetros de Instalación del paquete  SisProH     *"
    echoAndLog $MSGINFO "********************************************************"
    echoAndLog $MSGINFO "Directorio de configuración: $CONFDIR"
    echoAndLog $MSGINFO "Directorio de ejecutables: $BINDIR"
	echoAndLog $MSGINFO "Directorio de Maestros y Tablas: $MAEDIR"
    echoAndLog $MSGINFO "Directorio de recepcion de documentos para protocolizacion: $NOVEDIR"
    echoAndLog $MSGINFO "Espacio mínimo libre para arribos: $DATASIZE MB"
    echoAndLog $MSGINFO "Directorio de Archivos Aceptados: $ACEPDIR"
    echoAndLog $MSGINFO "Directorio de Archivos Rechazados: $RECHDIR"
    echoAndLog $MSGINFO "Directorio de Archivos Protocolizados: $PROCDIR"
    echoAndLog $MSGINFO "Directorio para informes y estadisticas: $INFODIR"
    echoAndLog $MSGINFO "Directorio para el repositorio de duplicados: $DUPDIR"
    echoAndLog $MSGINFO "Directorio para Archivos de Log: $LOGDIR"
    echoAndLog $MSGINFO "Tamaño máximo para los archivos de Log: $LOGSIZE Kb"
}

function confirmarConfiguracion() {
    echoAndLog $MSGINFO "Si los datos ingresados son correctos de ENTER para iniciar la instalacion"
    echoAndLog $MSGINFO "Si desea modificar algún parámetro oprima cualquier tecla para reiniciar"
    read -s -n1 respuesta

    if [ "$respuesta" = "" ]; then
        return 0
    else
        return 1
    fi
}

function confirmarInstalacion() {
    echoAndLog $MSGINFO "Iniciando Instalación… Está UD. seguro? (Si/No):"
    read respuesta
    if [ "$respuesta" = "" ] || [ `toLower $respuesta` != "si" ]; then
        echoAndLog $MSGINFO "Instalacion Cancelada\n"
        exit 1
    fi
}

function crearDirectorios() {
    echo "Creando estructuras de directorio..." 
	echo ""    
    crearDirectorio 775 "$GRUPO/$MAEDIR"
    crearDirectorio 775 "$GRUPO/$MAEDIR/tab"
	crearDirectorio 775 "$GRUPO/$MAEDIR/tab/ant"
    crearDirectorio 775 "$GRUPO/$BINDIR"
    crearDirectorio 775 "$GRUPO/$NOVEDIR"
    crearDirectorio 775 "$GRUPO/$LOGDIR"
    crearDirectorio 775 "$GRUPO/$ACEPDIR"
    crearDirectorio 775 "$GRUPO/$INFODIR"
    crearDirectorio 775 "$GRUPO/$RECHDIR"
    crearDirectorio 775 "$GRUPO/$PROCDIR"
    crearDirectorio 775 "$GRUPO/$PROCDIR/proc"
    crearDirectorio 775 "$GRUPO/$DUPDIR"
}

#Funcion para mover archivos
#Parametros:
#    1 - Archivo a mover
#    2 - Path destino del archivo
#    3 - Permisos del archivo
function moverArchivo() {
    if [ ! -f "$1" ]; then
        loguear $MSGERR "Archivo inexistente: ${1##*/}"
        return 1
    elif [ ! -d "$2" ]; then
        loguear $MSGERR "Directorio inexistente: $2"
        return 1
    else
        cp $1 $2 2>/dev/null
        if [ $? -ne 0 ]; then
            loguear $MSGERR "210:No se pudo mover el archivo: ${1##*/}"
            return 1
        else
            chmod "$3" "$2/${1##*/}" 2>/dev/null
        fi
    fi
}
######################################################################
#Se copian los scripts y los archivos asignandoles permisos
#los de $MAEDIR son de solo lectura y los otros lectura ejecución
function moverArchivos() {
    echo "Moviendo archivos Maestros y Tablas ..."
	echo ""
	#Lectura escritura para los archivos tab
	moverArchivo "$GRUPO/$INSTDIR/gestiones.mae" "$GRUPO/$MAEDIR" "664"
    moverArchivo "$GRUPO/$INSTDIR/emisores.mae" "$GRUPO/$MAEDIR" "664"
    moverArchivo "$GRUPO/$INSTDIR/normas.mae" "$GRUPO/$MAEDIR" "664"
    moverArchivo "$GRUPO/$INSTDIR/nxe.tab" "$GRUPO/$MAEDIR/tab" "664"
    moverArchivo "$GRUPO/$INSTDIR/axg.tab" "$GRUPO/$MAEDIR/tab" "664"
    echo "Instalando Programas y Funciones ..."
	echo ""    
    moverArchivo "$GRUPO/$INSTDIR/Start.sh" "$GRUPO/$BINDIR" "775"
    moverArchivo "$GRUPO/$INSTDIR/Stop.sh" "$GRUPO/$BINDIR" "775"
    moverArchivo "$GRUPO/$INSTDIR/Mover.sh" "$GRUPO/$BINDIR" "775"
    moverArchivo "$GRUPO/$INSTDIR/Glog.sh" "$GRUPO/$BINDIR" "775"
    moverArchivo "$GRUPO/$INSTDIR/IniPro.sh" "$GRUPO/$BINDIR" "775"
    moverArchivo "$GRUPO/$INSTDIR/RecPro.sh" "$GRUPO/$BINDIR" "775"
    moverArchivo "$GRUPO/$INSTDIR/ProPro.sh" "$GRUPO/$BINDIR" "775"
    moverArchivo "$GRUPO/$INSTDIR/InfPro.pl" "$GRUPO/$BINDIR" "775"
}
##############################################################
#Lectura de el archivo de configuración previa

function leerConfiguracion() {
    confAux=1
    if [ -f "$1" ]; then
        confAux=0
#        GRUPO=`grep "GRUPO" $CONFFILE | cut -s -f2 -d'='`
#        CONFDIR=`grep "CONFDIR" $CONFFILE | cut -s -f2 -d'='`
        AMAEDIR=`grep "MAEDIR" "$1" | cut -s -f2 -d'='`
        ABINDIR=`grep "BINDIR" "$1" | cut -s -f2 -d'='`
        ANOVEDIR=`grep "NOVEDIR" "$1" | cut -s -f2 -d'='`
        ADATASIZE=`grep "DATASIZE" "$1" | cut -s -f2 -d'='`
        ALOGSIZE=`grep "LOGSIZE" "$1" | cut -s -f2 -d'='`
        ALOGDIR=`grep "LOGDIR" "$1" | cut -s -f2 -d'='`
        AACEPDIR=`grep "ACEPDIR" "$1" | cut -s -f2 -d'='`
        AINFODIR=`grep "INFODIR" "$1" | cut -s -f2 -d'='`
        ARECHDIR=`grep "RECHDIR" "$1" | cut -s -f2 -d'='`
        APROCDIR=`grep "PROCDIR" "$1" | cut -s -f2 -d'='`
        ADUPDIR=`grep "DUPDIR" "$1" | cut -s -f2 -d'='`
    fi

        if [ "$ABINDIR" = "" ]; then
         #    echo "BINDIR No esta configurado correctamente"
            BBINDIR=1
        else
            BINDIR=$ABINDIR
        fi
        if [ "$AMAEDIR" = "" ]; then
         #   echo "MAEDIR No esta configurado correctamente"
            BMAEDIR=1
            else
            MAEDIR=$AMAEDIR
        fi
        if [ "$ANOVEDIR" = "" ]; then
         #   echo "NOVEDIR No esta configurado correctamente"
            BNOVEDIR=1
            else
            NOVEDIR=$ANOVEDIR
        fi
        if [ "$ADATASIZE" = "" ]; then
          #  echo "DATASIZE No esta configurado correctamente"
            BDATASIZE=1
            else
            DATASIZE=$ADATASIZE
        fi
        if [ "$ALOGSIZE" = "" ]; then
           # echo "LOGSIZE No esta configurado correctamente"
            BLOGSIZE=1
        fi
        if [ "$ALOGDIR" = "" ]; then
           # echo "LOGDIR No esta configurado correctamente"
            BLOGDIR=1
            else
            LOGDIR=$ALOGDIR
        fi
        if [ "$AACEPDIR" = "" ]; then
          #  echo "ACEPDIR No esta configurado correctamente"
            BACEPDIR=1
            else
            ACEPDIR=$AACEPDIR
        fi
        if [ "$AINFODIR" = "" ]; then
          #  echo "INFODIR No esta configurado correctamente"
            BINFODIR=1
            else
            INFODIR=$AINFODIR
        fi
        if [ "$ARECHDIR" = "" ]; then
          #  echo "RECHDIR No esta configurado correctamente"
            BRECHDIR=1
            else
            RECHDIR=$ARECHDIR
        fi
        if [ "$APROCDIR" = "" ]; then
          #  echo "PROCDIR No esta configurado correctamente"
            BPROCDIR=1
            else
            PROCDIR=$APROCDIR
        fi
        if [ "$ADUPDIR" = "" ]; then
          #  echo "DUPDIR No esta configurado correctamente"
            BDUPDIR=1
            else
            DUPDIR=$ADUPDIR
        fi

return $confAux;
}
function guardarGrupo() {
    echo "GRUPO=$GRUPO=$USER=`date +"%F %T"`" > "$1"
}
function guardarConf() {
    echo "CONFDIR=$CONFDIR=$USER=`date +"%F %T"`" >> "$1"
}
function guardarMae() {
    echo "MAEDIR=$MAEDIR=$USER=`date +"%F %T"`" >> "$1"
}
function guardarBin() {
echo "BINDIR=$BINDIR=$USER=`date +"%F %T"`" >> "$1"
}
function guardarNove() {
echo "NOVEDIR=$NOVEDIR=$USER=`date +"%F %T"`" >> "$1"
}
function guardarDatasize() {
    echo "DATASIZE=$DATASIZE=$USER=`date +"%F %T"`" >> "$1"
}
function guardarLogsize() {
    echo "LOGSIZE=$LOGSIZE=$USER=`date +"%F %T"`" >> "$1"
}
function guardarLog() {
    echo "LOGDIR=$LOGDIR=$USER=`date +"%F %T"`" >> "$1"
}
function guardarAcep() {
    echo "ACEPDIR=$ACEPDIR=$USER=`date +"%F %T"`" >> "$1"
}
function guardarInfo() {
    echo "INFODIR=$INFODIR=$USER=`date +"%F %T"`" >> "$1"
}
function guardarRech() {
echo "RECHDIR=$RECHDIR=$USER=`date +"%F %T"`" >> "$1"
}
function guardarProc() {
echo "PROCDIR=$PROCDIR=$USER=`date +"%F %T"`" >> "$1"
}
function guardarDup() {
    echo "DUPDIR=$DUPDIR=$USER=`date +"%F %T"`" >> "$1"
}
#No usada en la nueva version
function guardarConfiguracion() {
    echo "Actualizando la Configuracion del Sistema ..."
	echo ""    
    echo "GRUPO=$GRUPO=$USER=`date +"%F %T"`" > $CONFFILE    
    echo "CONFDIR=$CONFDIR=$USER=`date +"%F %T"`" >> $CONFFILE
    echo "MAEDIR=$MAEDIR=$USER=`date +"%F %T"`" >> $CONFFILE
    echo "BINDIR=$BINDIR=$USER=`date +"%F %T"`" >> $CONFFILE
    echo "NOVEDIR=$NOVEDIR=$USER=`date +"%F %T"`" >> $CONFFILE
    echo "DATASIZE=$DATASIZE=$USER=`date +"%F %T"`" >> $CONFFILE
    echo "LOGDIR=$LOGDIR=$USER=`date +"%F %T"`" >> $CONFFILE
    echo "LOGSIZE=$LOGSIZE=$USER=`date +"%F %T"`" >> $CONFFILE
    echo "ACEPDIR=$ACEPDIR=$USER=`date +"%F %T"`" >> $CONFFILE
    echo "INFODIR=$INFODIR=$USER=`date +"%F %T"`" >> $CONFFILE
    echo "RECHDIR=$RECHDIR=$USER=`date +"%F %T"`" >> $CONFFILE
    echo "PROCDIR=$PROCDIR=$USER=`date +"%F %T"`" >> $CONFFILE
    echo "DUPDIR=$DUPDIR=$USER=`date +"%F %T"`" >> $CONFFILE
}

#Funcion que detecta si estan todos los componentes instalados (Archivos)
#Return Codes:
#     0: Instalacion completa
#     1: Ningun componente instalado
#     2: Instalacion incompleta  
function detectarInstalacionArchivos {
    cantInst=0
    cantNoInst=0
    unset instalados
    unset noinstalados
    
    archivosAVerificar=(  "$GRUPO/$BINDIR/Start.sh"
                "$GRUPO/$BINDIR/Stop.sh"
                "$GRUPO/$BINDIR/Mover.sh"
                "$GRUPO/$BINDIR/Glog.sh"
                "$GRUPO/$BINDIR/IniPro.sh"
                "$GRUPO/$BINDIR/RecPro.sh"
                "$GRUPO/$BINDIR/ProPro.sh"
                "$GRUPO/$BINDIR/InfPro.pl"

                "$GRUPO/$MAEDIR/gestiones.mae"
                "$GRUPO/$MAEDIR/emisores.mae"
                "$GRUPO/$MAEDIR/normas.mae"
                "$GRUPO/$MAEDIR/tab/nxe.tab"
                "$GRUPO/$MAEDIR/tab/axg.tab"				
               )

    for archivo in ${archivosAVerificar[*]}
    do
        if [ -f "$archivo" ]; then

            instalados[$cantInst]="${archivo##*/}"
            let cantInst=$cantInst+1
        else
            noinstalados[$cantNoInst]="${archivo##*/}"
            let cantNoInst=$cantNoInst+1
        fi
    done
    
    if [  $cantInst -gt 0 ] && [ -f "$CONFFILE" ]; then
        if [ $cantNoInst -gt 0 ]; then 
            status=2 #Instalacion incompleta
        else
            status=0 #Instalacion completa
        fi                
    else
        status=1 #No se instalo ningun componente
    fi

    return $status
}
###############################################################################
# muestra  los componentes instalados y no instalados
function mostrarComponentesInstalados() {
    detectarInstalacionArchivos

    echo "*********************************************************************" 
    echo "*  TP SO7508 Primer Cuatrimestre 2015. Tema H Copyright © Grupo 08  *"
    loguear $MSGINFO "TP SO7508 Primer Cuatrimestre 2015. Tema H Copyright © Grupo 08"
    echo "*********************************************************************"
    
    if [ $cantInst -gt 0 ]; then
        echoAndLog $MSGINFO "* Se encuentran instalados los siguientes componentes:\n"
        arr=("${instalados[@]}")
        for index in ${!arr[*]}
        do
            echoAndLog $MSGINFO "  ${arr[$index]}"
        done
    fi

    if [ $cantNoInst -gt 0 ]; then 
        echoAndLog $MSGINFO "\n* Falta instalar los siguientes componentes:\n"
        for item in ${noinstalados[*]}
        do
            echoAndLog $MSGINFO "  $item"
        done
        echo ""
    fi
}
##Usando un archivo auxiliar, para poder recuperar una instalacion interumpida
function limpiarFileA() {
    `rm -rf "$CONFFILEAUX"`
    guardarGrupo "$CONFFILEAUX"
    guardarConf "$CONFFILEAUX"
}
function guardarFileA(){
    `mv "$CONFFILEAUX" "$CONFFILE"`
}
function chequearInstalacion () {

leerConfiguracion $CONFFILEAUX
resultConfAux=$?
#echo "Chequeo de .temp retorno=$resultConfAux"
resultCheck=0
if [ "$resultConfAux" -eq 2 ]; then #existe previa incompleta
resultCheck=1
fi
if [ "$resultConfAux" -eq 0 ]; then #existe completa
resultCheck=1
fi
if [ "$resultConfAux" -eq 1 ]; then #no existe
leerConfiguracion $CONFFILE
resultCheck=$?
fi
return $resultCheck
}
#------------------------------Main----------------------#

loguear $MSGINFO "Inicio de Ejecucion de InsPro"
loguear $MSGINFO "Directorio predefinido de Configuracion : CONFDIR"
loguear $MSGINFO "Log de la instalacion : CONFDIR/InsPro.log"
#clear
chequeoInicial
chequearInstalacion
detectarInstalacionArchivos
case "$?" in 
    0 )     #Instalacion completa
        mostrarComponentesInstalados
        echoAndLog $MSGINFO "La Instalacion ya esta COMPLETA. Proceso de Instalacion Cancelado.\n"
        exit 0;;

    1 ) #No hay instalacion previa
        presentacion
        verificarPerl
        mensajesInformativos
        modifica=1
        while [ $modifica -ne 0 ]; do
            limpiarFileA
            definirDirBinarios
            definirDirMae
            definirDirNovedades
            definirDatasize
            definirDirAceptados
            definirDirInformes
            definirDirLog
            definirLogsize
            definirDirRechazados
            definirDirProtocolizados
            definirDirDuplicados
            # clear
            mostrarConfiguracion
            confirmarConfiguracion
            modifica=$?
        done;;

    2 ) #Instalacion previa incompleta
        mostrarComponentesInstalados
        mostrarConfiguracion;;
esac

confirmarInstalacion
crearDirectorios
moverArchivos
#guardarConfiguracion
guardarFileA
mostrarComponentesInstalados
echo "********************************************************" 
echoAndLog $MSGINFO "Instalacion COMPLETA"
echo "********************************************************" 
exit $?
