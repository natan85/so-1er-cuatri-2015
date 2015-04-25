#!/bin/bash

# *************************************************************************
# (75.08) Sistemas Operativos  fiuba
# 1er Cuatrimestre 2015
# Grupo 08 - Trabajo Practico H
# *************************************************************************
# Comando Stop.sh : No recibe opciones ni parametros.
# Es invocado desde la linea de comandos para detener el demonio RecPro.sh
# y muestra el resultado de su uso en pantalla.
# *************************************************************************


killall RecPro.sh > /dev/null
if [ $? -ne 0 ]
	then
		echo "RecPro.sh no esta corriendo."
	else
		echo "RecPro.sh fue terminado."
fi

