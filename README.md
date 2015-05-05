Archivo README

EXPLICACIÓN DE INSTALACIÓN Y USO

********************************************************
 COPIAR INSTALABLE DESDE MEDIO EXTERNO
********************************************************

a) Inserte el dispositivo externo con el programa comprimido
b) Cree en el directorio corriente un directorio de trabajo
c) Copie el archivo *.tgz en el directorio creado
d) Descomprima el archivo *.tgz de manera de generar un archivo *.tar con el mismo nombre
e) Extraiga los archivos del .tar
f) Elimine tanto el archivo *.tgz como el archivo *.tar del directorio de trabajo

***************************************
         	INSTALACIÓN
***************************************

a) Abra una terminal de consola
b) Párese en el directorio de trabajo donde copió los archivos del instalable:

    > cd /PATH_DEL_DIRECTORIO/

c) Ejecute el comando:

    >./InsPro.sh

d) Siga los pasos de instalación del programa. El mismo le informará cuando se haya terminado la instalación y los posibles errores, si los hubiera

***************************************
       	POST-INSTALACIÓN
***************************************

La instalación creará los siguientes directorios:

    - NOVEDIR
    - MAEDIR
    - PROCDIR
    - ACEPDIR
    - DUPDIR
    - INFODIR
    - BINDIR
    - LOGDIR
    - RECHDIR

En las direcciones que haya elegido el usuario.

Dentro de MAEDIR se generarán 3 archivos (normas.mae, emisores.mae  y gestiones.mae) y un directorio (tab).
Dentro del directorio tab se generarán 2 archivos: nxg.tab y axg.tab
Dentro del directorio conf habrá 2 archivos:

    - InsPro.conf, que tendrá las variables de ambiente del programa
    - InsPro.log, que tendrá el log de instalación

***************************************
 PRIMEROS PASOS PARA CORRER EL PAQUETE
***************************************

a) Desde la consola, parado sobre el directorio de trabajo, ejecute:

	> bin/IniPro.sh

b) Siga las instrucciones del programa.
c) Se pondrá a correr el comando RecPro.
d) Para mandar un archivo a protocolizar, copie el archivo en el directorio NOVEDIR.
e) Espere.
f) Luego de 30 segundos, checkee que se haya movido el archivo del directorio NOVEDIR. Checkee si apareció en el directorio RECHDIR. De estar ahí, checkee el log de RecPro (LOGDIR/RecPro/RecPro.log) para ver las razones del rechazo. Sino, checkee que se encuentre en ACEPDIR.
g) Espere
h) Luego de 30 segundos, checkee que se haya movido el archivo del directorio ACEPDIR. Checkee si apareció en PROCDIR bajo el directorio con nombre igual al código de gestión del archivo provisto. De ser así, se habrá generado un archivo con el nombre <AÑO_NORMA>.<CODIGO_DE_NORMA>. 
   Sino, checkee si apareció en el directorio RECHDIR. De estar ahí, checkee el log de ProPro (LOGDIR/ProPro/ProPro.log) para ver las razones del rechazo del archivo.
i) Si el archivo aparece en PROCDIR, checkee si aparecen todos los registros, con número de protocolo. 
Si algún registro falta, checkee si en PROCDIR tiene un archivo con nombre <CODIGO_DE_GESTION>.rech. Allí estarán los registros rechazados. Checkee el log de ProPro (LOGDIR/ProPro/ProPro.log) para ver las razones del rechazo de cada registro.

***************************************
  CHECKEO DE CONDICIONES PARA EMPEZAR
***************************************

?

***************************************
    FRENADO DE EJECUCIÓN DE COMANDOS
***************************************

Para frenar la ejecución de un comando:

a) Párese en el directorio de trabajo
b) Ejecute desde la terminal el siguiente comando:

	> bin/Stop.sh <NOMBRE_DE_COMANDO>

c) Si el comando estaba siendo ejecutado, se informará que fue frenado. Si por alguna razón no se pudo detener, se mostrará un mensaje de error. Si no hay ningún comando con el nombre provisto, se informará que no se encontró tal comando para frenar.

