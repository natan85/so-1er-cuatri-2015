EXPLICACIÓN DE INSTALACIÓN Y USO

***************************************
 COPIAR INSTALABLE DESDE MEDIO EXTERNO
***************************************
	a) Montar el dispositivo de almacenamiento con el contenido del TP (pen drive, cd, etc).
	b) Extraer el contenido del paquete so1c2015g8.tgz en una ubicación temporal.
	c) Asegurarse que el usuario posea permisos de escritura en esa ubicacion.

	c) Por ejemplo para extraer en temp, ejecutar exactamente los siguientes comandos:
	- mkdir temp
	- tar xvzf <dispositivo>/so1c2015g8.tgz -C temp
	- cd temp

***************************************
             INSTALACIÓN
***************************************

a) Abra una terminal de consola
b) Párese en el directorio de trabajo donde copió los archivos del instalable:
	
	> cd PATH_DEL_DIRECTORIO

c) Ejecute el comando:

	> ./InsPro.sh

* la instalacion no posee argumentos, que consideramos no necesarios.

d) Siga los pasos de instalación del programa. El mismo le informará cuando se haya terminado la instalación y los posibles errores, si los hubiera


Supuestos:

Se tienen permisos escritura sobre el path donde se encuentra.
Las distintas rutas configuradas durante la instalacion deben corresponder a directorios inexistentes.

Resultado:

La instalación creará los siguientes directorios:

	- NOVEDIR
	- MAEDIR
	- PROCDIR
	- PROTDIR
	- DUPDIR
	- INFDIR
	- BINDIR
	- LOGDIR
	- RECHDIR


En las direcciones que haya elegido el usuario. 

Dentro de MAEDIR se generarán 2 archivos (normas.mae y gestiones.mae) y un directorio (tab). 
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

