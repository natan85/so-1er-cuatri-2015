#!/bin/bash

# *************************************************************************
# (75.08) Sistemas Operativos  fiuba
# 1er Cuatrimestre 2015
# Grupo 08 - Trabajo Practico H
# *************************************************************************
# Comando Start.sh
# Opciones y Parámetros
#   Parámetro 1 (obligatorio): comando a iniciar
# *************************************************************************

# Verifico ambiente inicializado
if ! [ $AMBIENTE_INICIALIZADO ] 
then
	echo "El ambiente no ha sido inicializado previamente, debe inicializarlo mediante el comando IniPro.sh "
	exit 1
fi 

COMANDO=$1

if [ $# -ne 1 ]
then
	echo "No se enviaron los parametros correctos."
        "$GRUPO/$BINDIR/Glog.sh" Start "No se enviaron los parametros correctos." ERR
	exit 1
fi

if [ "grep \"RecPro.sh\" $COMANDO" = "" ]
then
	echo "Se ha llamado a Start con un comando no reconocido."
	"$GRUPO/$BINDIR/Glog.sh" Start "Se ha llamado a start con un comando no reconocido." ERR
	exit 1
fi

# Si ya esta corriendo el comando, entonces no tengo que seguir
PID=`ps | grep "RecPro.sh" | head -1 | awk '{print $1 }'`
if [ ! -z "$PID" ]
then
	echo "$COMANDO ya se esta ejecutando, se ignora el pedido."
	"$GRUPO/$BINDIR/Glog.sh" Start "$COMANDO ya se esta ejecutando, se ignora el pedido." WAR
else
	"$GRUPO/$BINDIR/$COMANDO" > /dev/null 2>"$GRUPO/$LOGDIR/stderr.log" &
	PID=$!
	echo "Ejecutando $COMANDO, PID=$PID."
	"$GRUPO/$BINDIR/Glog.sh" Start "Ejecutando $COMANDO, PID=$PID." INFO
fi
#exit 0

