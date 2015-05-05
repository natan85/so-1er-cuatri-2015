#!/usr/bin/perl -w
use strict;
use warnings;
use Fcntl qw(:flock);
use feature qw/switch/; 
use Switch;
our %filtros;

our %emisoresDesc;

our %posCamposArchConsulta = (
			'fechaNorma' => 1,
			'numero' => 2,	
			'anio' => 3,		
			'causante' => 4,
			'extracto' => 5,
			'idReg' => 10,	
			'gestion' => 11,		
			'tipoNorma' => 12,
			'emisor' => 13,
			);

our %posCamposArchInfo = (
			'tipoNorma' => 0,
			'descEmisor' => 1,	
			'emisor' => 2,		
			'numero' => 3,
			'anio' => 4,
			'gestion' => 5,	
			'fechaNorma' => 6,		
			'causante' => 7,
			'extracto' => 8,
			'idReg' => 9,
			);

our %posCamposGestiones = (
			'codigo' => 0,
			'fechaDesde' => 1,	
			'fechaHasta' => 2,		
			'descripcion' => 3,
			);

our %posCamposEmisores = (
			'codigo' => 0,
			'descripcion' => 1,	
			);

our %posCamposNormas = (
			'codigo' => 0,
			'descripcion' => 1,	
			);

our %descripcionFiltros;
our $pidioGuardar = 0;
our $sinPalabraClave = 1;
our $palabraClave;
our %contenido_resultados_consola;
our %contenido_resultados_archivo;
###### Se valida que el comando no este en ejecución#####
open(my $script_fh, '<', $0)
   or die("No se pudo abrir el archivo: $!\n");

unless (flock($script_fh, LOCK_EX|LOCK_NB)) {
    print "$0 ya se encuentra en ejecución.\n";
    exit(1);
}

###### Se valida ejecucion de IniPro######
# Si no existen las variables de ambiente sabemos que IniPro no se ejecuto
if (!exists($ENV{"MAEDIR"}) && !exists($ENV{"PROCDIR"}) && !exists($ENV{"INFODIR"}) && !exists($ENV{"NOVEDIR"}))
{
	 print "Previamente debe ejecutar el comando IniPro\n";
     exit(1);	  
} 

###### MENU ##############################
###### Si no ingresa ningún parametro se mostrará la ayuda
my $num_parametros = $#ARGV + 1;

if ($num_parametros < 1) {
    print "Debe ingresar una opción.\n";
    mostrarAyuda();
    exit;
}else{
	my $primero=$ARGV[0];
	if($primero eq "-a") { mostrarAyuda(); }
	elsif($primero eq "-c") { consultar();}
	elsif($primero eq "-i") { informar(); }
	elsif($primero eq "-e") { estadisticas();}
	else { 
		print "Opción incorrecta.\n";
    		mostrarAyuda();
    		exit;
    	}
}

####### Declaración de funciones ###### 
 
sub mostrarAyuda {

print "Ayuda: InfPro [opción] [argumentos] 
	  -a                  			Muestra esta ayuda.
	  -g                  			Grabar. Se utiliza como complemento de -c o -i. Ej: -c 'Resolucion' -g
	  -c[palabra clave]   			Consulta por palabra clave.
	  -i[lista de archivos resultado]   	Información
	  -e                  			Estadísticas\n";
}

sub consultar{
	cargarMapaEmisores();
	validarPalabraClaveYGuardar();
	menuFiltros();
}

sub informar{
	validarPalabraClaveYGuardar();
	cargarMapaEmisores();
	menuFiltros();	
} 

sub validarPalabraClaveYGuardar
{
	my $parametro = $ARGV[1];
	if(!defined $parametro){
		$sinPalabraClave = 1;		
	}
	if (defined $parametro and $parametro eq "-g")	{
		$sinPalabraClave = 1;				
		$pidioGuardar = 1;		
	}
	if (defined $parametro and $parametro ne "-g")	{
		
		$palabraClave = $parametro;		
		$sinPalabraClave = 0;	
		my $parametro2 = $ARGV[2];
	
		if (defined $parametro2 and $parametro2 eq "-g")	
		{
			$pidioGuardar = 1;		
		}		
	}
}

sub leerArchivosSubdirectoriosResultados
{
	my $ruta = $ENV{"INFODIR"};
	print "Ruta de Informar $ruta \n";
	#Si pasaron la lista de archivos
	if($#ARGV > 1) 
	{
		my $i = 1;
		while($i < $#ARGV){
			my $file = $ARGV[$i];
			buscarEnArchivo($file,$ruta,%posCamposArchInfo);
		}	
		
	}else{
		opendir (DIR, $ruta) or die $!;
		#Leo cada archivo
		while (my $file = readdir(DIR)) {
			buscarEnArchivo($file,$ruta,%posCamposArchInfo);		
	   	 }

    		closedir(DIR);
	}

	imprimirYGrabarResultadosOrdenados();
}

sub leerTodosArchivosSubdirectorios
{
	my $dir = $ENV{"PROCDIR"};
	my $DIR;
	# Leo el directorio raiz
	opendir $DIR, $dir or die "opendir $dir - $!";
	my @entries = readdir $DIR;

	# Obtengo los subdirectorio
	my @subdirs = grep { -d "$dir/$_" } @entries;

	# Elimino los directorios ocultos
	@subdirs = grep { !/^\./ } @subdirs;
	print "Raiz: $dir \n";
	for my $subdir ( @subdirs ) {
		if (exists($filtros{'-fg'})){
			my $gestion = $filtros{'-fg'}; 
			if(defined $gestion and ($subdir eq $gestion)){
				print "Subdirectorio: $subdir \n";
				buscarEnDirectorio($dir."/".$subdir);	
			}
		}else{
			print "Subdirectorio: $subdir \n";
			buscarEnDirectorio($dir."/".$subdir);
		}
		
	}

	imprimirYGrabarResultadosOrdenados();	
	closedir $DIR;
}

sub buscarEnDirectorio
{
	my $subdirCompleto = $_[0]; 
	opendir (SUBDIR, $subdirCompleto) or die $!;
	#Leo cada archivo
	while (my $file = readdir(SUBDIR)) {
		#print "Archivo: $file \n";
		buscarEnArchivo($file,$subdirCompleto,%posCamposArchConsulta);		
   	}#Del while archivos
	closedir(SUBDIR);
}

sub buscarEnArchivo
{
	my $file = $_[0]; 
	my $ruta = $_[1]; 
	my (%posCamposArch) = @_;
	my $filename = $ruta.'/'.$file;
	open(my $fh, '<:encoding(UTF-8)', $filename)
	 or die "No se pudo abrir el archivo '$filename' $!";
		#Leo cada linea 
		while (my $row = <$fh>) {
			chomp $row;
			#Inicializo variables de filtrado
			my $cumplioCausal = 0;
			my $cumplioExtracto = 0;

			#Busco los valores de causal y extracto		
			my @data = split(";",$row);
			my $causal = $data[$posCamposArch{'causante'}];
			my $extracto = $data[$posCamposArch{'extracto'}];
			#leerArchivo($file);
			if ($sinPalabraClave == 1){
				$cumplioCausal = 1;
				$cumplioExtracto = 1;
			}else{
				if (defined $causal and defined $palabraClave and index(lc($causal), lc($palabraClave)) != -1) {
				   $cumplioCausal = 1; 
				}
				if(defined $extracto and defined $palabraClave and index(lc($extracto), lc($palabraClave)) != -1){
				   $cumplioExtracto = 1;	
				}

			}			

			#Busco por filtro Tipo Norma
			my $tipoNorma = $data[$posCamposArch{'tipoNorma'}];
			my $cumplioFiltroTipoNorma = validarCumplioFiltroTipoNorma($tipoNorma);

			#Busco por filtro Año
			my $anio = $data[$posCamposArch{'anio'}];
			my $cumplioFiltroAnio = validarCumplioFiltroAnio($anio);
	
			#Busco por filtro numero Norma
			my $numero = $data[$posCamposArch{'numero'}];
			my $cumplioFiltroNumeroNorma = validarCumplioFiltroNumeroNorma($numero);

			#Busco por filtro Gestion
			my $gestion = $data[$posCamposArch{'gestion'}];
			my $cumplioFiltroGestion = validarCumplioFiltroGestion($gestion);
			
			#Busco por filtro Emisor
			my $emisor = $data[$posCamposArch{'emisor'}];
			my $cumplioFiltroEmisor = validarCumplioFiltroEmisor($emisor);
			

			if (($cumplioCausal == 1 or $cumplioExtracto == 1) and $cumplioFiltroTipoNorma == 1 and $cumplioFiltroAnio == 1 and $cumplioFiltroNumeroNorma == 1 and $cumplioFiltroGestion == 1 and $cumplioFiltroEmisor == 1){
				#Armamos la salida por consola
				my $fechaNorma = $data[$posCamposArch{'fechaNorma'}];	
				my $descEmisor = $emisoresDesc{$emisor};	
				my $renglon1 = $tipoNorma." ".$descEmisor."(".$emisor.") ".$numero."/".$anio." ".$gestion." ".$fechaNorma;
				my $peso;				
				if($sinPalabraClave == 0 and defined $palabraClave){
					$peso = obtenerPeso($causal, $extracto, $palabraClave);
					$renglon1 .= " ".$peso;
				}
				$renglon1 .= " \n";
				my $renglon2 = $extracto."\n";
				my $renglon3 = $causal."\n";
				#Cargamos en la lista para luego ordenar
				my $idReg = $data[$posCamposArch{'idReg'}];
				my $lineaSalida = $tipoNorma.";".$descEmisor.";".$emisor.";".$numero.";".$anio.";".$gestion.";".$fechaNorma.";".$causal.";".$extracto.";".$idReg."\n";
				
				if($sinPalabraClave == 0){
					$contenido_resultados_consola{$peso."-".$idReg} = $renglon1.$renglon2.$renglon3;
					$contenido_resultados_archivo{$peso."-".$idReg} = $lineaSalida;	
				}else{
					my $nombreFecha = obtenerNombreDeFecha($fechaNorma);					
					$contenido_resultados_consola{$nombreFecha."-".$idReg} = $renglon1.$renglon2.$renglon3;
					$contenido_resultados_archivo{$nombreFecha."-".$idReg} = $lineaSalida;	
				}		
				
				
			}
	}#Del while lineas
	close($fh);
}
#**************************METODS PARA CARGAS INICIALES ***********************************
sub cargarMapaEmisores
{
	my $ruta = $ENV{"MAEDIR"};
	my $filename = $ruta.'/emisores.mae';
	open(my $fh, '<:encoding(UTF-8)', $filename)
	 or die "No se pudo abrir el archivo '$filename' $!";
		#Leo cada linea 
		while (my $row = <$fh>) {
			chomp $row;
			my @data = split(";",$row);
			my $descripcion = $data[$posCamposEmisores{'descripcion'}];
			my $codigo = $data[$posCamposEmisores{'codigo'}];
			$emisoresDesc{$codigo} = $descripcion;
		}
	close ($fh);
}

sub cargarFiltrosYValidarGuardar
{
	#Cargamos los filtros
	my $i = 1;
	while($i < $#ARGV){
		my $parametro = $ARGV[$i]; 
		if ($parametro eq "-ft" or $parametro eq "-fa" or $parametro eq "-fn" or $parametro eq "-fg" or $parametro eq "-fe" ){
			if(!exists($filtros{$parametro} ) ){
				my $valorFiltro = $ARGV[$i+1]; 					
				$filtros{$parametro} = $valorFiltro;
				$i += 2;					
			}	
		}else{
			$i += 1;
		}
			
	}

	#Validamos si se ingreso guardar
	if($i <= $#ARGV){
		my $ultimaEntrada = $ARGV[$#ARGV];
		if(defined $ultimaEntrada and $ultimaEntrada eq "-g"){
			$pidioGuardar = 1;	
		}
	}

}



#*************METODOS VALIDADORES DE COINCIDENCIAS***************************************

sub validarCumplioFiltroEmisor
{
	my $cumplioFiltroEmisor = 0;	
	my $emisor = $_[0];	
	my $emisorIngresado;
	if(exists($filtros{'-fe'}) ){
		#El usuario ingreso la descripcion, buscamos el codigo para validar en registros.
		#my $emisorDesc = $filtros{'-fe'};
		#$emisorIngresado = $descripcionFiltros{$emisorDesc};
		$emisorIngresado = $filtros{'-fe'};  
	}else{
		$cumplioFiltroEmisor = 1;	
	}

	if (defined $emisor and defined $emisorIngresado and index($emisor, $emisorIngresado) != -1) {
	   $cumplioFiltroEmisor = 1; 
	}
	return $cumplioFiltroEmisor;
}


sub validarCumplioFiltroGestion
{
	my $cumplioFiltroGestion = 0;	
	my $gestion = $_[0];	
	my $gestionIngresada;
	if(exists($filtros{'-fg'}) ){
		#El usuario ingreso la descripcion, buscamos el codigo para validar en registros.
		#my $gestionDesc = $filtros{'-fg'};
		#$gestionIngresada = $descripcionFiltros{$gestionDesc}; 
		$gestionIngresada = $filtros{'-fg'};
	}else{
		$cumplioFiltroGestion = 1;	
	}
			
	if (defined $gestion and defined $gestionIngresada and index(lc($gestion), lc($gestionIngresada)) != -1) {
	   $cumplioFiltroGestion = 1; 
	}
	return $cumplioFiltroGestion;
}

sub validarCumplioFiltroNumeroNorma
{
	my $cumplioFiltroNumeroNorma = 0;	
	my $numero = $_[0];		
	my $numeroIngresado;
	if(exists($filtros{'-fn'}) ){
		$numeroIngresado = $filtros{'-fn'}; 
	}else{
		$cumplioFiltroNumeroNorma = 1;	
	}
	
	if (defined $numero and defined $numeroIngresado and ($numero eq $numeroIngresado)) {
	   $cumplioFiltroNumeroNorma = 1; 
	}
	return  $cumplioFiltroNumeroNorma;
}

sub validarCumplioFiltroTipoNorma
{
	my $cumplioFiltroTipoNorma = 0;	
	my $tipoNorma = $_[0];	
	my $normaIngresada;
	if(exists($filtros{'-ft'}) ){
		#El usuario ingreso la descripcion, buscamos el codigo para validar en registros.
		#my $normaDesc = $filtros{'-ft'};
		#$normaIngresada = $descripcionFiltros{$normaDesc}; 
		$normaIngresada = $filtros{'-ft'};
	}else{
		$cumplioFiltroTipoNorma = 1;	
	}

	if (defined $tipoNorma and defined $normaIngresada  and (lc($tipoNorma) eq lc($normaIngresada))) {
	   $cumplioFiltroTipoNorma = 1; 
	}
	return $cumplioFiltroTipoNorma;
}

sub validarCumplioFiltroAnio
{
	my $cumplioFiltroAnio = 0;	
	my $anio = $_[0];		
	my $anioIngresado; 
	if(exists($filtros{'-fa'}) ){
		$anioIngresado = $filtros{'-fa'}; 
	}else{
		$cumplioFiltroAnio = 1;
	}

	if (defined $anio and defined $anioIngresado  and ($anio eq $anioIngresado)) {
	   $cumplioFiltroAnio = 1; 
	}
	return $cumplioFiltroAnio;
}
#*******************************************************************************

sub imprimirYGrabarResultadosOrdenados()
{
	my $resultadoArchivo;		    
	print "********Resultados********\n";		
	foreach my $keyHash (sort{$b cmp $a} keys %contenido_resultados_consola) {
		my $resultado = $contenido_resultados_consola{$keyHash};
		print "$resultado\n";
		if ($pidioGuardar == 1){
			$resultadoArchivo .= $contenido_resultados_archivo{$keyHash};	
		}
	    }
	print "**************************\n";

	if($pidioGuardar == 1){
		grabar($resultadoArchivo);	
	}	

}


sub grabar
{
	my $resultado = $_[0];
	my $ruta = $ENV{"INFODIR"};
	my $epoc = time();
	my $nombreArchivo = $ruta."/resultado_".$epoc;
	open FILE, ">".$nombreArchivo or die $!; 
	print FILE $resultado; 
	close FILE;
	print "Se generó el archivo $nombreArchivo\n";
}

#*************************METODOS AUXILIARES PARA OBTENCION DE DATOS********************
sub obtenerCodigoGestion
{
	my $gestionBuscada = $_[0];
	my $ruta = $ENV{"MAEDIR"};
	my $filename = $ruta.'/gestiones.mae';
	open(my $fh, '<:encoding(UTF-8)', $filename)
	 or die "No se pudo abrir el archivo '$filename' $!";
		#Leo cada linea 
		while (my $row = <$fh>) {
			chomp $row;
			my @data = split(";",$row);
			my $descripcion = $data[$posCamposGestiones{'descripcion'}];
			if (defined $descripcion and defined $gestionBuscada and index($descripcion, $gestionBuscada) != -1){
				return  $data[$posCamposGestiones{'codigo'}];
			}
		}
	close($fh);
}

sub obtenerCodigoEmisor
{
	my $emisorBuscado = $_[0];
	my $ruta = $ENV{"MAEDIR"};
	my $filename = $ruta.'/emisores.mae';
	open(my $fh, '<:encoding(UTF-8)', $filename)
	 or die "No se pudo abrir el archivo '$filename' $!";
		#Leo cada linea 
		while (my $row = <$fh>) {
			chomp $row;
			my @data = split(";",$row);
			my $descripcion = $data[$posCamposEmisores{'descripcion'}];
			if (defined $descripcion and defined $emisorBuscado and ($descripcion eq $emisorBuscado) ){
				return  $data[$posCamposEmisores{'codigo'}];
			}
		}
	close($fh);
}


sub obtenerCodigoNorma
{
	my $normaBuscada = $_[0];
	my $ruta = $ENV{"MAEDIR"};
	my $filename = $ruta.'/normas.mae';
	open(my $fh, '<:encoding(UTF-8)', $filename)
	 or die "No se pudo abrir el archivo '$filename' $!";
		#Leo cada linea 
		while (my $row = <$fh>) {
			chomp $row;
			my @data = split(";",$row);
			my $descripcion = $data[$posCamposNormas{'descripcion'}];
			if (defined $descripcion and defined $normaBuscada and ($descripcion eq $normaBuscada)){
				my $codigoNorma = $posCamposNormas{'codigo'};				
				print "Codigo norma: $codigoNorma \n";
				return $data[$posCamposNormas{'codigo'}];
			}
		}
	close ($fh);
}

sub obtenerNombreDeFecha
{
	my $fecha = $_[0]; 
	my @data = split("/",$fecha);
	my $nombre = $data[2].$data[1].$data[0];
	return $nombre;
}


sub obtenerPeso
{
	my $causal = $_[0];
	my $extracto = $_[1];
	my $palabraClave = $_[2];
	my $contadorCausal = () = $causal =~ /$palabraClave/g;
	my $contadorExtracto = () = $extracto =~ /$palabraClave/g;
	my $peso = $contadorCausal*10+$contadorExtracto;
	return $peso;
}
#*********************************************************************************************


sub imprimirFiltros
{
	print "Consulta ingresada: \n";		
	if(defined $palabraClave){
		print "Palabra clave: $palabraClave \n";		
	}	

	foreach my $name (keys %filtros) {
	    	printf "%-8s %s\n", $name, $filtros{$name};
	}
}

sub imprimirEmisores
{
	print "Maestro Emisores: \n";	
	foreach my $name (keys %emisoresDesc) {
	    	printf "%-8s %s\n", $name, $emisoresDesc{$name};
	}
}


sub menuFiltros
{
	
	my $input = '';

	while ($input ne '10')
	{
	    #clear_screen();
	    print " \n";
 	    print "************MENÚ************ \n";		
	    print "1. Ingresar palabra clave\n".
		  "2. Filtrar por tipo de norma\n".
		  "3. Filtrar por año [año o año desde-año hasta]\n". 
		  "4. Filtrar por numero de norma [norma o norma desde-norma hasta]\n". 
		  "5. Filtrar por gestión\n". 
		  "6. Filtrar por emisor\n".
		  "7. Ejecutar consulta\n".
		  "8. Mostrar consulta\n".
		  "9. Limpiar consulta\n".
		 "10. Salir\n";

	    print "Ingrese su opción: ";
	    $input = <STDIN>;
	    chomp($input);

	    switch ($input)
	    {
		case '1'
		{
		    
		    print "Ingrese palabra clave: ";
		    my $palabra = <STDIN>;
		    chomp($palabra);
		    $palabraClave = $palabra;	
		    $sinPalabraClave = 0;	
		    $input = '';

		}

		case '2'
		{
		    print "Ingrese el tipo de norma: ";
		    my $tipo = <STDIN>;
		    chomp($tipo);
		    $filtros{"-ft"} = $tipo;	
		    #Para la busqueda por descripcion
		    #$descripcionFiltros{$tipo} = obtenerCodigoNorma($tipo);			
		    $input = ''; 
		}

		case '3'
		{
		    print "Ingrese el año o rango: ";
		    my $anio = <STDIN>;
		    chomp($anio);
		    $filtros{"-fa"} = $anio;		
		    $input = '';
		}

		case '4'
		{
		    print "Ingrese el número o rango: ";
		    my $numero = <STDIN>;
		    chomp($numero);
		    $filtros{"-fn"} = $numero;		
		    $input = '';
		}

		case '5'
		{
		    print "Ingrese la gestión: ";
		    my $gestion = <STDIN>;
		    chomp($gestion);
		    $filtros{"-fg"} = $gestion;
		    #Para la busqueda por descripcion	
		    #$descripcionFiltros{$gestion} = obtenerCodigoGestion($gestion);		
		    $input = '';
		}

		case '6'
		{
		    print "Ingrese el emisor: ";
		    my $emisor = <STDIN>;
		    chomp($emisor);
		    $filtros{"-fe"} = $emisor;	
		    #Para la busqueda por descripcion
		    #$descripcionFiltros{$emisor} = obtenerCodigoEmisor($emisor);		
		    $input = '';
		}

		case '7'
		{
			
			my $cantFiltrosCargados = keys %filtros;
			if($cantFiltrosCargados > 0){
				my $opcion=$ARGV[0];
				imprimirFiltros();
				if($opcion eq "-c"){
					leerTodosArchivosSubdirectorios();		   
				}
				if($opcion eq "-i"){
					leerArchivosSubdirectoriosResultados();
				}				

			}else{
				print "Debe realizar al menos un filtro. \n";
			}
			
			limpiarMapas();			
			
		   #ejecutarConsulta();
		}
		case '8'
		{
		    imprimirFiltros();
		}
		case '9'
		{
		    %filtros = ();
		}

	    }#del switch
	}#del while

	exit(0);
}

sub limpiarMapas(){
	%contenido_resultados_archivo = ();			
	%contenido_resultados_consola = ();
	#%filtros = ();
	#%descripcionFiltros = ();	
}

sub clear_screen
{
    system("clear");
}

sub estadisticas
{
	print "Se eligió -e\n"; 
}
