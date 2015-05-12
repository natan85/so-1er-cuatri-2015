#!/usr/bin/perl -w
use strict;
use warnings;
use Fcntl qw(:flock);
use feature qw/switch/; 
use Switch;
our %filtros;
our %normasDesc;
our %gestionesDesc;
our %emisoresDesc;
our %emisoresArchivoDesc;

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
our %registrosEstadisticos ; #aca se guardan todos los registros que se mostraran por pantalla
our $listaEmisores;


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
cargarMapaGestiones();
cargarMapaEmisores();
cargarMapaNormas();

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
	validarPalabraClaveYGuardar();
	menuFiltros();
}

sub informar{
	validarGuardarInforme();
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

sub validarGuardarInforme
{
	my $ultimaEntrada = $ARGV[$#ARGV];
	#print "ultima entrada: $ultimaEntrada";
	if(defined $ultimaEntrada and $ultimaEntrada eq "-g"){
		$pidioGuardar = 1;	
	}

}


sub leerArchivosSubdirectoriosResultados
{
	my $ruta = $ENV{"GRUPO"}.'/'.$ENV{"INFODIR"};
	#Si pasaron la lista de archivos
	if($#ARGV > 1) 
	{
		my $i = 1;
		my $final = $#ARGV;
		if($pidioGuardar == 1){
			$final -= 1; 	
		}
	        print "Final: $final \n";
		while($i <= $final){
			my $file = $ARGV[$i];
			if (index(lc($file), lc('resultado')) != -1){
				buscarEnArchivo($file,$ruta,%posCamposArchInfo);
			}
			$i+= 1;
		}	
		
	}else{
		opendir (DIR, $ruta) or die $!;
		#Leo cada archivo
		while (my $file = readdir(DIR)) {
			if (index(lc($file), lc('resultado')) != -1){
				buscarEnArchivo($file,$ruta,%posCamposArchInfo);
			}
	   	 }

    		closedir(DIR);
	}

	imprimirYGrabarResultadosOrdenados();
}

sub leerTodosArchivosSubdirectorios
{
	my $dir = $ENV{"GRUPO"}.'/'.$ENV{"PROCDIR"};
	my $DIR;
	# Leo el directorio raiz
	opendir $DIR, $dir or die "opendir $dir - $!";
	my @entries = readdir $DIR;

	# Obtengo los subdirectorio
	my @subdirs = grep { -d "$dir/$_" } @entries;

	# Elimino los directorios ocultos
	@subdirs = grep { !/^\./ } @subdirs;
	for my $subdir ( @subdirs ) {
		if (exists($filtros{'-fg'})){
			my $gestion = $filtros{'-fg'}; 
			if(defined $gestion and (lc($subdir) eq lc($gestion))){
				#print "Subdirectorio: $subdir \n";
				buscarEnDirectorio($dir."/".$subdir);	
			}
		}else{
			my $gestionMapa = $gestionesDesc{lc($subdir)};
			if(defined $gestionMapa){
				#print "Subdirectorio: $subdir \n";
				buscarEnDirectorio($dir."/".$subdir);
			}
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
	open(ENT,"<$filename")|| die "NO SE PUEDE REALIZAR LA CONSULTA. No se encontro el archivo $filename \n";
		#Leo cada linea 
		while (my $row = <ENT>) {
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
					$peso = obtenerPeso(lc($causal), lc($extracto), lc($palabraClave));
					print "Peso: $peso";
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
	close(ENT);
}
#**************************METODS PARA CARGAS INICIALES ***********************************
sub cargarMapaEmisores
{
	my $ruta = $ENV{"GRUPO"}.'/'.$ENV{"MAEDIR"};
	my $filename = $ruta.'/emisores.mae';
	open(my $fh,"<$filename")|| die "NO SE PUEDE REALIZAR LA CONSULTA. No se encontro el archivo $filename \n";
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

sub cargarMapaNormas
{
	my $ruta = $ENV{"GRUPO"}.'/'.$ENV{"MAEDIR"};
	my $filename = $ruta.'/normas.mae';
	open(my $fh, '<:encoding(UTF-8)', $filename)
	 or die "No se pudo abrir el archivo '$filename' $!";
		#Leo cada linea 
		while (my $row = <$fh>) {
			chomp $row;
			my @data = split(";",$row);
			my $descripcion = $data[$posCamposNormas{'descripcion'}];
			my $codigo = $data[$posCamposNormas{'codigo'}];
			$normasDesc{lc($codigo)} = $descripcion;
		}
	close ($fh);
}

sub cargarMapaGestiones
{
	my $ruta = $ENV{"GRUPO"}.'/'.$ENV{"MAEDIR"};
	my $filename = $ruta.'/gestiones.mae';
	open(my $fh, '<:encoding(UTF-8)', $filename)
	 or die "No se pudo abrir el archivo '$filename' $!";
		#Leo cada linea 
		while (my $row = <$fh>) {
			chomp $row;
			my @data = split(";",$row);
			my $descripcion = $data[$posCamposGestiones{'descripcion'}];
			my $codigo = $data[$posCamposGestiones{'codigo'}];
			$gestionesDesc{lc($codigo)} = $descripcion;
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
	my $rangoIngresado;
	if(exists($filtros{'-fn'}) ){
		$rangoIngresado = $filtros{'-fn'}; 
	}else{
		$cumplioFiltroNumeroNorma = 1;	
	}
	
	if (defined $numero and defined $rangoIngresado) {
	   my @numeros = split("-",$rangoIngresado); 
	   my $fechaDesde = $numeros[0];
	   my $fechaHasta = $numeros[1]; 
	   if ($numero >= $fechaDesde and $numero <= $fechaHasta){
		$cumplioFiltroNumeroNorma = 1; 
	    }
	   
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
	my $rangoIngresado; 
	if(exists($filtros{'-fa'}) ){
		$rangoIngresado = $filtros{'-fa'}; 
	}else{
		$cumplioFiltroAnio = 1;
	}

	if (defined $anio and defined $rangoIngresado) {
		my @anios = split("-",$rangoIngresado); 
		my $anioDesde = $anios[0];
		my $anioHasta = $anios[1]; 
		if ($anio >= $anioDesde and $anio <= $anioHasta){
			$cumplioFiltroAnio = 1; 
		}
	}
	return $cumplioFiltroAnio;
}
#*******************************************************************************

sub imprimirYGrabarResultadosOrdenados()
{
	my $resultadoArchivo;	
	my @sortKeysHash;	    
	print "********Resultados********\n";	
	if(defined $palabraClave){
		@sortKeysHash = sort {
		     
		     my @aValues = split('-', $a);
		     my @bValues = split('-', $b);

		     if($aValues[0] > $bValues[0]) {
			 return -1;
		     }
		     elsif($bValues[0] > $aValues[0]) {
			  return +1;
		     }
		     else {
			return 0;
		     }
		  }keys %contenido_resultados_consola;	
	}else{
		@sortKeysHash = sort{$b cmp $a} keys %contenido_resultados_consola;		
	}	
	foreach my $keyHash (@sortKeysHash){
		my $resultado = $contenido_resultados_consola{$keyHash};
		print "$resultado\n";
		if ($pidioGuardar == 1){
			$resultadoArchivo .= $contenido_resultados_archivo{$keyHash};	
		}
	    }
	print "**************************\n";

	if($pidioGuardar == 1){
		grabar($resultadoArchivo,"resultado");	
	}	

}


sub grabar
{
	my $resultado = $_[0];
	my $nombre = $_[1];
	my $ruta = $ENV{"GRUPO"}.'/'.$ENV{"INFODIR"};
	my $epoc = time();
	my $nombreArchivo = $ruta."/".$nombre."_".$epoc.".txt";
	
	if(defined $resultado){
		open FILE, ">".$nombreArchivo or die $!; 
		print FILE "$resultado\n"; 
		close FILE;
		print "Se generó el archivo $nombreArchivo\n";
	}else{
		print "La consulta no produjo resultados.\n";
	}

}


#*************************METODOS AUXILIARES PARA OBTENCION DE DATOS********************
sub obtenerCodigoGestion
{
	my $gestionBuscada = $_[0];
	my $ruta = $ENV{"GRUPO"}.'/'.$ENV{"MAEDIR"};
	my $filename = $ruta.'/gestiones.mae';
	open(my $fh,"<$filename")|| die "NO SE PUEDE REALIZAR LA CONSULTA. No se encontro el archivo $filename \n";
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
	my $ruta = $ENV{"GRUPO"}.'/'.$ENV{"MAEDIR"};
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
	my $ruta = $ENV{"GRUPO"}.'/'.$ENV{"MAEDIR"};
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

	if($pidioGuardar == 1){
		print "Se pidió guardar resultados.\n";	
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

	imprimirOpcionesMenu();

	while ($input ne '10')
	{
	    #clear_screen();
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
		    my $normaMapa = $normasDesc{lc($tipo)};
		    if(defined $normaMapa){
			$filtros{"-ft"} = $tipo;
		    }else{
			print "Tipo de norma incorrecta. Intente de nuevo.\n";
		    }
		    #Para la busqueda por descripcion
		    #$descripcionFiltros{$tipo} = obtenerCodigoNorma($tipo);			
		    $input = ''; 
		}

		case '3'
		{
		    print "Ingrese Año Desde: ";
		    my $anioDesde = <STDIN>;
		    chomp($anioDesde);
		    print "Ingrese Año Hasta: ";
		    my $anioHasta = <STDIN>;
		    chomp($anioHasta);
		    if ($anioDesde > $anioHasta){
		    	print "Año Desde debe ser menor que Años Hasta. Intente de nuevo.\n";		
		    }else{
			$filtros{"-fa"} = $anioDesde."-".$anioHasta;		
		    }
		    $input = '';
		}

		case '4'
		{
		    print "Ingrese Número Desde: ";
		    my $numeroDesde = <STDIN>;
		    chomp($numeroDesde);
		    print "Ingrese Número Hasta: ";
		    my $numeroHasta = <STDIN>;
		    chomp($numeroHasta);
		    if ($numeroDesde > $numeroHasta){
		    	print "Número Desde debe ser menor que Número Hasta. Intente de nuevo.\n";		
		    }else{
			$filtros{"-fn"} = $numeroDesde."-".$numeroHasta;		
		    }
		    $input = '';
		}

		case '5'
		{
		    print "Ingrese la gestión: ";
		    my $gestion = <STDIN>;
		    chomp($gestion);
		    my $gestionMapa = $gestionesDesc{lc($gestion)};
		    if(defined $gestionMapa){
			$filtros{"-fg"} = $gestion;
		    }else{
			print "Gestión incorrecta. Intente de nuevo.\n";
		    }
		    
		    #Para la busqueda por descripcion	
		    #$descripcionFiltros{$gestion} = obtenerCodigoGestion($gestion);		
		    $input = '';
		}

		case '6'
		{
		    print "Ingrese el emisor: ";
		    my $emisor = <STDIN>;
		    chomp($emisor);
		    my $emisorMapa = $emisoresDesc{lc($emisor)};
		    if(defined $emisorMapa){
			$filtros{"-fe"} = $emisor;
		    }else{
			print "Emisor incorrecto. Intente de nuevo.\n";
		    }
		    #Para la busqueda por descripcion
		    #$descripcionFiltros{$emisor} = obtenerCodigoEmisor($emisor);		
		    $input = '';
		}

		case '7'
		{
			my $cantFiltrosCargados = keys %filtros;
			if($cantFiltrosCargados > 0){
				my $opcion=$ARGV[0];
				#imprimirFiltros();
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
			imprimirOpcionesMenu();		
		}
		case '8'
		{
		    imprimirFiltros();
		}
		case '9'
		{
		    %filtros = ();
		}
		case '10'
		{
		    
		}
		else{
			print "Opción Incorrecta! \n";
		}

	    }#del switch
	}#del while

	exit(0);
}

sub imprimirOpcionesMenu{
	    print " \n";
 	    print "************MENÚ************ \n";		
	    print "1. Ingresar palabra clave\n".
		  "2. Filtrar por tipo de norma\n".
		  "3. Filtrar por año\n". 
		  "4. Filtrar por numero de norma\n". 
		  "5. Filtrar por gestión\n". 
		  "6. Filtrar por emisor\n".
		  "7. Ejecutar consulta\n".
		  "8. Mostrar consulta\n".
		  "9. Limpiar consulta\n".
		 "10. Salir\n";
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


#*****************Estadisticas*********************
sub menu_estadistica
{ 


#$registrosEstadisticos {anio_normas}[0]=2007;
#$registrosEstadisticos {cantDisp}[0]=4;
#$registrosEstadisticos {cantRes}[0]=0;
#$registrosEstadisticos {cantConv}[0]=0;

#$registrosEstadisticos {anio_normas}[1]=2008;
#$registrosEstadisticos {cantDisp}[1]=51;
#$registrosEstadisticos {cantRes}[1]=0;


#print "estadisticas: \n";	
	#foreach my $name (keys %registrosEstadisticos) {
	    	#print "$name";
	#	for my $i ( 0 .. $#{ $registrosEstadisticos{$name} } ) {
               		#print " $name = $registrosEstadisticos{$name}[$i] \n";      
    		#}
	#}
	#imprimirGestiones();

	my $input = '';

	while ($input ne '3')
	{
	    #clear_screen();
	    print " \n";
 	    print "************MENÚ Estadisticas************ \n";		
	    print "1. Filtrar por año [año o año desde-año hasta]\n". 
		  "2. Filtrar por gestión\n". 
		  "3. Salir\n";

	    print "Ingrese su opción: ";
	    $input = <STDIN>;
	    chomp($input);

	    switch ($input)
	    {
		case '1'
		{
		    print "Ingrese el año o rango: ";
		    my $anio = <STDIN>;
		    chomp($anio);
		    $filtros{"-fa"} = $anio;		
		    $input = '';
		}
		case '2'
		{
		    print "Ingrese la gestión: ";
		    my $gestion = <STDIN>;
		    chomp($gestion);
		    $filtros{"-fg"} = $gestion;
		    #Para la busqueda por descripcion	
		    #$descripcionFiltros{$gestion} = obtenerCodigoGestion($gestion);		
		    $input = '';
		    leerPorGestion(lc($gestion));
                    imprimirGestiones(lc($gestion));
		    #print "Emisores Archivo: \n";	
			#foreach my $name (keys %emisoresArchivoDesc) {
			 #   	printf "%-8s %s\n", $name, $emisoresArchivoDesc{$name};
			#}	
		}
		case '3'{}
		else{
			print "Opción Incorrecta! \n";
		}

	    }#del switch
	}#del while

	exit(0);             
}

sub imprimirGestiones
{
	my $gestion=$_[0];
         
            #print "gestion: $gestionesDesc{$gestion} ,\n";

        my $resultadoArchivo = ""; 
	for my $j ( 0 .. $#{ $registrosEstadisticos{anio_normas} } ) 
	{
	        my $gestionDescripcion = $gestionesDesc{lc($gestion)}; 
		if(defined $gestionDescripcion){
		       $resultadoArchivo.= "gestion: $gestionDescripcion\n";
		} 
		$resultadoArchivo.= "Año: $registrosEstadisticos{anio_normas}[$j] \n";
		$resultadoArchivo.= "Emisores:  \n";
		$resultadoArchivo.= "$registrosEstadisticos{emisores}[$j]";	
		$resultadoArchivo.= "Cantidad de resoluciones: $registrosEstadisticos{res}[$j] \n";
		$resultadoArchivo.= "Cantidad de disposiciones: $registrosEstadisticos{dis}[$j] \n";
		$resultadoArchivo.= "Cantidad de convenios: $registrosEstadisticos{con}[$j] \n";
         }
		
	print $resultadoArchivo;
	if($pidioGuardar == 1){
		grabar($resultadoArchivo,"estadistica");	
	}

}

sub leerPorGestion
{
        my $gestion=$_[0];
	my $dir = $ENV{"GRUPO"}.'/'.$ENV{"PROCDIR"};
	my $DIR;
	opendir $DIR, $dir or die "opendir $dir - $!";
	my @entries = readdir $DIR;

	# Obtengo los subdirectorio
	my @subdirs = grep { -d "$dir/$_" } @entries;

	# Elimino los directorios ocultos
	@subdirs = grep { !/^\./ } @subdirs;
	for my $subdir ( @subdirs ) {
		if (lc($gestion) eq lc($subdir)){
		   #print "nombre de las carpetas: $subdir\n";
		   ProcesarGestion($dir."/".$subdir);

	       }
   	}
	closedir $DIR;
}

sub ProcesarGestion
{
        my $subdirCompleto = $_[0]; 
        my $cant_registros=0;
        my $i=0;
        
	my $extension='';
	opendir(DIR,$subdirCompleto) || die "No se pudo abrir $subdirCompleto\n";
	my @nodos = grep(!/^\./, (sort(readdir(DIR)))); # esquiva archivos ocultos, . y ..
	closedir(DIR); 
        my $nodoViejo='';
        #inicializo con 0
                 $registrosEstadisticos {res}[$i]=0;
                 $registrosEstadisticos {dis}[$i]=0;
                 $registrosEstadisticos {con}[$i]=0;

	foreach my $nodo (@nodos)  
	{
		 #$nodo = $dir.'/'.$nodo; 
		 my $nombreArchivo = $nodo;
                 $extension = ($nodo =~ m/([^.]+)$/)[0]; #guarda la extension del archivo porque me sirve para el hash
                 $nodo=~ s{\.[^.]+$}{}; #elimina la extensión del nombre del archivo
		 my $keyArchivo = lc($extension)."-".$nodo;  
		 $cant_registros= contarRegistros ($nombreArchivo,$subdirCompleto,lc($extension),$nodo);

                
      		 if ($nodo eq $nodoViejo)
			{  #si entra acá es porque se repite el año, entonces  hay q disminuir el contador y no hay q inicializar
                                 $i--;
          			 $registrosEstadisticos {anio_normas}[$i]=$nodo;      
          			 $registrosEstadisticos {lc($extension)}[$i]=$cant_registros;
				 $registrosEstadisticos {emisores}[$i]=$emisoresArchivoDesc{$keyArchivo};
                                 $i++;
			} else 
        		{  #si entra acá es porque no se repite el año
                                 
                		#inicializo con 0
               		        $registrosEstadisticos {res}[$i]=0;
                 		$registrosEstadisticos {dis}[$i]=0;
                 	        $registrosEstadisticos {con}[$i]=0;
                 		$registrosEstadisticos {anio_normas}[$i]=$nodo;
                 		$registrosEstadisticos {lc($extension)}[$i]=$cant_registros;
				$registrosEstadisticos {emisores}[$i]=$emisoresArchivoDesc{$keyArchivo};
                	        $i++; 
        		}
       
                         $nodoViejo=$nodo; 
		     
                 #print "años $nodo ,$cant_registros \n";
	}
		#print "estadisticas: \n";	
	    	#print "$name";		
}

# le pasan el nombre y la ruta y retorna la cantidad de registros de un archivo
sub contarRegistros
{ 
    	my $file = $_[0]; 
	my $ruta = $_[1]; 
	my $gestion = $_[2];
	my $anio = $_[3];
	my $keyArchivo = $gestion."-".$anio;
	my (%posCamposArch) = @_;
	my $filename = $ruta.'/'.$file;
	open(my $fh,"<$filename")|| die "NO SE PUEDE REALIZAR LA ACCIÓN. No se encontro el archivo $filename \n";
	#Leo cada linea 
          my $count = 0;
          while(my $row = <$fh> ) { 
		chomp($row);
		my @data = split(";",$row);
		my $codigoEmisor = $data[$posCamposArchConsulta{'emisor'}];
 		my $emisorMapa = $emisoresDesc{lc($codigoEmisor)};
		if (exists($emisoresArchivoDesc{$keyArchivo})){
			my $emisorArchDesc = $emisoresArchivoDesc{$keyArchivo};
			#No esta agregado el emisor
			if(index(lc($emisorArchDesc),lc($emisorMapa)) == -1){
				$emisoresArchivoDesc{$keyArchivo} = $emisorArchDesc.$emisorMapa."\n";		
			}	
		}else{
			$emisoresArchivoDesc{$keyArchivo} = $emisorMapa."\n";
		}
		$count++; 
	  }
          #print "cantidad de registros $count \n";
	close($fh);
        return $count;
}

sub estadisticas
{
	#imprimirGestiones();
	validarGuardarInforme();
	menu_estadistica();
}

1;#necesario
