#!/usr/bin/perl -w
use strict;
use warnings;
use Fcntl qw(:flock);
use feature qw/switch/; 
our %filtros;
our @filtrosValidos = ('-ft','-fa','-fn','-fg','-fe');
our $pidioGuardar = 0;
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
		  -a                  Muestra esta ayuda
		  -g                  Grabar
		  -c[palabra clave]   Consulta por palabra clave
		  -i                  Información
		  -e                  Estadísticas\n";
}


sub consultar{
	cargarFiltrosYValidarGuardar();
	my $cantFiltros = keys %filtros;
	#print "$cantFiltros \n";
	if($cantFiltros < 1 ){
		print "Debe utilizar al menos un filtro\n";	
	}else{
		leerTodosArchivos();
	}
}

sub leerTodosArchivos{
	#my $palabraClave = shift;
	my $palabraClave = $ARGV[1];
	my $sinPalabraClave = 0;
	if($palabraClave eq "-ft" or $palabraClave eq "-fa" or $palabraClave eq "-fn" or $palabraClave eq "-fg" or $palabraClave eq "-fe")	{
		$sinPalabraClave = 1;		
	}
	my $ruta = $ENV{"PROCDIR"};
	opendir (DIR, $ruta) or die $!;
	
	#Leo cada archivo
	while (my $file = readdir(DIR)) {
		my $filename = $ruta.'/'.$file;
		open(my $fh, '<:encoding(UTF-8)', $filename)
		 or die "Could not open file '$filename' $!";

		#Leo cada linea 
		while (my $row = <$fh>) {
			chomp $row;
			#Inicializo variables de filtrado
			my $cumplioCausal = 0;
			my $cumplioExtracto = 0;
			my $cumplioFiltroTipoNorma = 0;
			my $cumplioFiltroAnio = 0;
			my $cumplioFiltroNumeroNorma = 0;
			my $cumplioFiltroGestion = 0;
			my $cumplioFiltroEmisor = 0;

			#Busco los valores de causal y extracto		
			my @data = split(";",$row);
			my $causal = $data[4];
			my $extracto = $data[5];
			#leerArchivo($file);
			if ($sinPalabraClave == 1){
				$cumplioCausal = 1;
				$cumplioExtracto = 1;
			}else{
				if (defined $causal and index($causal, $palabraClave) != -1) {
				   $cumplioCausal = 1; 
				}
				if(defined $extracto and index($extracto, $palabraClave) != -1){
				   $cumplioExtracto = 1;	
				}

			}			

			#Busco por filtro Tipo Norma
			my $tipoNorma = $data[12];
			my $normaIngresada;
			if(exists($filtros{'-ft'}) ){
				$normaIngresada = $filtros{'-ft'}; 
			}else{
				$cumplioFiltroTipoNorma = 1;	
			}
			
			if (defined $tipoNorma and defined $normaIngresada  and index($tipoNorma, $normaIngresada) != -1) {
			   $cumplioFiltroTipoNorma = 1; 
			}

			#Busco por filtro Año
			my $anio = $data[3];
			my $anioIngresado; 
			if(exists($filtros{'-fa'}) ){
				$anioIngresado = $filtros{'-fa'}; 
			}else{
				$cumplioFiltroAnio = 1;
			}

			if (defined $anio and defined $anioIngresado  and index($anio, $anioIngresado) != -1) {
			   $cumplioFiltroAnio = 1; 
			}
			#Busco por filtro numero Norma
			my $numero = $data[2];
			my $numeroIngresado;
			if(exists($filtros{'-fn'}) ){
				$numeroIngresado = $filtros{'-fn'}; 
			}else{
				$cumplioFiltroNumeroNorma = 1;	
			}
				
			if (defined $numero and defined $numeroIngresado and index($numero, $numeroIngresado) != -1) {
			   $cumplioFiltroNumeroNorma = 1; 
			}
			#Busco por filtro Gestion
			my $gestion = $data[11];
			my $gestionIngresada;
			if(exists($filtros{'-fg'}) ){
				$gestionIngresada = $filtros{'-fg'}; 
			}else{
				$cumplioFiltroGestion = 1;	
			}
						
			if (defined $gestion and defined $gestionIngresada and index($gestion, $gestionIngresada) != -1) {
			   $cumplioFiltroGestion = 1; 
			}
			#Busco por filtro Emisor
			my $emisor = $data[13];
			my $emisorIngresado;
			if(exists($filtros{'-fe'}) ){
				$emisorIngresado = $filtros{'-fe'}; 
			}else{
				$cumplioFiltroEmisor = 1;	
			}
 
			if (defined $emisor and defined $emisorIngresado and index($emisor, $emisorIngresado) != -1) {
			   $cumplioFiltroEmisor = 1; 
			}

			if (($cumplioCausal == 1 or $cumplioExtracto == 1) and $cumplioFiltroTipoNorma == 1 and $cumplioFiltroAnio == 1 and $cumplioFiltroNumeroNorma == 1 and $cumplioFiltroGestion == 1 and $cumplioFiltroEmisor == 1){
				#Armamos la salida por consola
				my $fechaNorma = $data[1];		
				my $peso = obtenerPeso($causal, $extracto, $palabraClave);
				my $renglon1 = $tipoNorma." ".$emisor." ".$numero."/".$anio." ".$gestion." ".$fechaNorma;
				if($sinPalabraClave == 0){
					$renglon1 .= " ".$peso;
				}
				$renglon1 .= " \n";
				my $renglon2 = $extracto."\n";
				my $renglon3 = $causal."\n";
				#Cargamos en la lista para luego ordenar
				my $idReg = $data[10];
				my $lineaSalida = $tipoNorma." ".$emisor." ".$numero." ".$anio." ".$gestion." ".$fechaNorma." ".$causal." ".$extracto." ".$idReg."\n";
				
				if($sinPalabraClave == 0){
					$contenido_resultados_consola{$peso."-".$file.$idReg} = $renglon1.$renglon2.$renglon3;
					$contenido_resultados_archivo{$peso."-".$file.$idReg} = $lineaSalida;	
				}else{
					my $nombreFecha = obtenerNombreDeFecha($fechaNorma);					
					$contenido_resultados_consola{$nombreFecha."-".$file.$idReg} = $renglon1.$renglon2.$renglon3;
					$contenido_resultados_archivo{$nombreFecha."-".$file.$idReg} = $lineaSalida;	
				}		
				
				
			}
	
		}#Del while lineas
   	 }#Del while archivos
	
	imprimirYGrabarResultadosOrdenados();

    	closedir(DIR);
}

sub imprimirYGrabarResultadosOrdenados(){
	my $resultadoArchivo;		    
	foreach my $keyHash (sort{$b cmp $a} keys %contenido_resultados_consola) {
		my $resultado = $contenido_resultados_consola{$keyHash};
	    	print "$resultado\n";
		if ($pidioGuardar == 1){
			$resultadoArchivo .= $contenido_resultados_archivo{$keyHash};	
		}
	    }
	if($pidioGuardar == 1){
		grabar($resultadoArchivo);	
	}	

}


sub grabar{
	my $resultado = $_[0];
	my $ruta = $ENV{"INFODIR"};
	my $epoc = time();
	my $nombreArchivo = $ruta."/resultado_".$epoc;
	open FILE, ">".$nombreArchivo or die $!; 
	print FILE $resultado; 
	close FILE;
	print "Se generó el archivo $nombreArchivo\n";
}

sub obtenerNombreDeFecha{
	my $fecha = $_[0]; 
	my @data = split("/",$fecha);
	my $nombre = $data[2].$data[1].$data[0];
	return $nombre;
}


sub obtenerPeso{
	my $causal = $_[0];
	my $extracto = $_[1];
	my $palabraClave = $_[2];
	my $contadorCausal = () = $causal =~ /$palabraClave/g;
	my $contadorExtracto = () = $extracto =~ /$palabraClave/g;
	my $peso = $contadorCausal*10+$contadorExtracto;
	return $peso;
}

sub cargarFiltrosYValidarGuardar{
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

	foreach my $name (keys %filtros) {
	    	printf "%-8s %s\n", $name, $filtros{$name};
	}
}

sub informar{
	print "Se eligió -i\n";
}

sub estadisticas{
	print "Se eligió -e\n"; 
}
